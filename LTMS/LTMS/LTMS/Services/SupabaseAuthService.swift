//
//  SupabaseAuthService.swift
//  LTMS
//
//  Created for Supabase Integration
//

import Foundation
import Combine
import Supabase
import Auth

enum SupabaseAuthError: LocalizedError {
    case userNotFound
    case invalidCredentials
    case emailAlreadyInUse
    case weakPassword
    case networkError
    case accountDeactivated
    case notConfigured
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found. Please check your credentials."
        case .invalidCredentials:
            return "Invalid email or password."
        case .emailAlreadyInUse:
            return "This email is already registered."
        case .weakPassword:
            return "Password should be at least 6 characters."
        case .networkError:
            return "Network error. Please check your connection."
        case .accountDeactivated:
            return "This account has been deactivated. Please contact your administrator."
        case .notConfigured:
            return "Supabase is not configured. Please add Supabase-Info.plist with your credentials."
        case .unknown(let message):
            return message
        }
    }
}

@MainActor
class SupabaseAuthService: ObservableObject {
    static let shared = SupabaseAuthService()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    
    private let client: SupabaseClient
    private let service: SupabaseService
    
    private init() {
        self.client = SupabaseConfig.shared.client
        self.service = SupabaseService.shared
        
        // Check if user is already authenticated
        Task {
            await checkAuthStatus()
        }
    }
    
    // MARK: - Authentication Status
    
    func checkAuthStatus() async {
        do {
            // Get current session
            let session = try await client.auth.session
            
            // Load user data from database
            if let userId = session.user.id.uuidString as String? {
                await loadUserData(uid: userId)
            }
        } catch {
            print("No active session: \(error)")
            isAuthenticated = false
            currentUser = nil
        }
    }
    
    // MARK: - Sign In
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // Check if Supabase is configured
        guard SupabaseConfig.shared.isConfigured else {
            // Fallback to mock authentication for testing
            print("⚠️ Supabase not configured, using mock authentication")
            try await mockSignIn(email: email, password: password)
            return
        }
        
        do {
            // Try Supabase Auth first
            let session = try await client.auth.signIn(
                email: email,
                password: password
            )
            
            print("✅ Signed in successfully with Supabase: \(session.user.email ?? "")")
            
            // Load user data from database
            await loadUserData(uid: session.user.id.uuidString)
            
            // Check if account is active
            if let user = currentUser, !user.isActive {
                try await signOut()
                throw SupabaseAuthError.accountDeactivated
            }
            
            // Update last login
            if let userId = currentUser?.id {
                var updatedUser = currentUser!
                updatedUser.lastLogin = Date()
                _ = try await service.update(updatedUser, id: userId, in: SupabaseConstants.users)
            }
            
        } catch {
            // If Supabase auth fails, try mock authentication
            // This allows existing mock users (like admin) to still login
            print("⚠️ Supabase auth failed, trying mock authentication...")
            print("   Error: \(error.localizedDescription)")
            
            do {
                try await mockSignIn(email: email, password: password)
                print("✅ Signed in successfully with mock authentication")
            } catch {
                // If both fail, throw the original Supabase error
                print("❌ Both Supabase and mock auth failed")
                throw mapAuthError(error)
            }
        }
    }
    
    // MARK: - Sign Up
    
    func signUp(
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        role: UserRole,
        organizationId: String
    ) async throws {
        // Check if Supabase is configured
        guard SupabaseConfig.shared.isConfigured else {
            print("⚠️ Supabase not configured, using mock signup")
            try await mockSignUp(
                email: email,
                password: password,
                firstName: firstName,
                lastName: lastName,
                role: role,
                organizationId: organizationId
            )
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            print("🔵 Starting signup for: \(email)")
            
            // Create auth user with email confirmed (for admin-created users)
            // Using data to mark as confirmed
            let authResponse = try await client.auth.signUp(
                email: email,
                password: password,
                data: ["email_confirmed": true]
            )
            
            let userId = authResponse.user.id.uuidString
            
            print("🔵 Auth user created: \(userId)")
            
            // Create user profile in database
            let user = User(
                id: userId,
                organizationId: organizationId,
                email: email,
                role: role,
                firstName: firstName,
                lastName: lastName,
                profilePictureURL: nil,
                isActive: true,
                createdAt: Date(),
                updatedAt: Date(),
                lastLogin: Date()
            )
            
            print("🔵 Saving user profile to database...")
            let createdUser = try await service.create(user, in: SupabaseConstants.users)
            
            print("🔵 User profile saved successfully!")
            currentUser = createdUser
            isAuthenticated = true
            
        } catch let error as SupabaseAuthError {
            throw error
        } catch {
            print("🔴 Signup error: \(error)")
            throw mapAuthError(error)
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() async throws {
        do {
            try await client.auth.signOut()
            currentUser = nil
            isAuthenticated = false
            print("✅ Signed out successfully")
        } catch {
            print("❌ Sign out error: \(error)")
            throw SupabaseAuthError.unknown(error.localizedDescription)
        }
    }
    
    // MARK: - Load User Data
    
    private func loadUserData(uid: String) async {
        do {
            let user: User = try await service.fetch(id: uid, from: SupabaseConstants.users)
            currentUser = user
            isAuthenticated = true
            
            print("✅ User data loaded: \(user.fullName) (\(user.role.displayName))")
        } catch {
            print("❌ Error loading user data: \(error)")
            isAuthenticated = false
            currentUser = nil
        }
    }
    
    // MARK: - Mock Authentication (for testing without Supabase)
    
    private func mockSignIn(email: String, password: String) async throws {
        // Check if user exists in MockDataService
        let existingUser = MockDataService.shared.getUserByEmail(email)
        
        if let user = existingUser {
            // Validate password
            if !MockDataService.shared.validateCredentials(email: email, password: password) {
                throw SupabaseAuthError.invalidCredentials
            }
            
            // Check if account is active
            if !user.isActive {
                throw SupabaseAuthError.accountDeactivated
            }
            
            print("🔍 Mock Login: \(user.fullName) (\(user.role.displayName))")
            
            self.currentUser = user
            self.isAuthenticated = true
            return
        }
        
        throw SupabaseAuthError.userNotFound
    }
    
    private func mockSignUp(
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        role: UserRole,
        organizationId: String
    ) async throws {
        try? await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network delay
        
        let mockUser = User(
            id: UUID().uuidString,
            organizationId: organizationId,
            email: email,
            role: role,
            firstName: firstName,
            lastName: lastName,
            profilePictureURL: nil,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date(),
            lastLogin: Date()
        )
        
        // Save to MockDataService
        MockDataService.shared.addUser(mockUser, password: password)
        
        self.currentUser = mockUser
        self.isAuthenticated = true
        
        print("✅ Mock signup successful: \(mockUser.fullName)")
    }
    
    // MARK: - OTP Methods for 2FA Signup
    
    /// Check if email already exists in the database
    func checkEmailExists(email: String) async throws -> Bool {
        do {
            // Query users table for email
            let users: [User] = try await service.fetchAll(from: SupabaseConstants.users)
            return users.contains { $0.email.lowercased() == email.lowercased() }
        } catch {
            print("❌ Error checking email existence: \(error)")
            throw SupabaseAuthError.unknown("Failed to check email")
        }
    }
    
    /// Send OTP to email for verification
    func sendOTP(email: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Use Supabase Auth OTP
            try await client.auth.signInWithOTP(
                email: email
            )
            print("✅ OTP sent to \(email)")
        } catch {
            print("❌ Error sending OTP: \(error)")
            throw SupabaseAuthError.unknown("Failed to send OTP. Please try again.")
        }
    }
    
    /// Verify OTP and create user account
    func verifyOTPAndCreateUser(
        email: String,
        token: String,
        userData: PendingUserData
    ) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Verify OTP
            let session = try await client.auth.verifyOTP(
                email: email,
                token: token,
                type: .email
            )
            
            let userId = session.user.id.uuidString
            print("✅ OTP verified successfully for user: \(userId)")
            
            // Set the user's password so they can log in with email/password
            print("🔵 Setting user password...")
            try await client.auth.update(user: .init(password: userData.password))
            print("✅ Password set successfully")
            
            // Now create user profile in database
            let user = User(
                id: userId,
                organizationId: AppConstants.defaultOrganizationId,
                email: email,
                role: userData.role,
                firstName: userData.firstName,
                lastName: userData.lastName,
                profilePictureURL: nil,
                isActive: true,
                createdAt: Date(),
                updatedAt: Date(),
                lastLogin: Date()
            )
            
            let createdUser = try await service.create(user, in: SupabaseConstants.users)
            
            currentUser = createdUser
            isAuthenticated = true
            
            print("✅ User account created successfully!")
            
        } catch {
            print("❌ Error verifying OTP: \(error)")
            let errorMessage = error.localizedDescription.lowercased()
            
            // Check for duplicate user errors
            if errorMessage.contains("duplicate") || errorMessage.contains("unique constraint") || errorMessage.contains("already exists") {
                throw SupabaseAuthError.unknown("User already exists. Try signing in.")
            } else {
                throw SupabaseAuthError.unknown("Invalid or expired OTP code")
            }
        }
    }
    
    /// Resend OTP to email
    func resendOTP(email: String) async throws {
        try await sendOTP(email: email)
    }
    
    // MARK: - Error Mapping
    
    private func mapAuthError(_ error: Error) -> SupabaseAuthError {
        let errorMessage = error.localizedDescription.lowercased()
        
        if errorMessage.contains("user not found") || errorMessage.contains("invalid login") {
            return .invalidCredentials
        } else if errorMessage.contains("email") && errorMessage.contains("already") {
            return .emailAlreadyInUse
        } else if errorMessage.contains("password") && errorMessage.contains("weak") {
            return .weakPassword
        } else if errorMessage.contains("network") {
            return .networkError
        } else {
            return .unknown(error.localizedDescription)
        }
    }
}
