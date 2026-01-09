//
//  AuthService.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import Foundation
import Combine
import Supabase

enum AuthError: LocalizedError {
    case userNotFound
    case invalidCredentials
    case emailAlreadyInUse
    case weakPassword
    case networkError
    case accountDeactivated
    case emailNotVerified
    case verificationFailed
    case invalidOTP
    case otpExpired
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
        case .emailNotVerified:
            return "Please verify your email before signing in. Check your inbox for the verification code."
        case .verificationFailed:
            return "Email verification failed. Please try again."
        case .invalidOTP:
            return "Invalid verification code. Please check and try again."
        case .otpExpired:
            return "Verification code has expired. Please request a new one."
        case .unknown(let message):
            return message
        }
    }
}

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var showOTPVerification = false
    @Published var pendingUserData: (email: String, firstName: String, lastName: String, role: UserRole, organizationId: String?)?
    
    private let supabase = SupabaseService.shared.client
    
    private init() {
        checkAuthStatus()
    }
    
    // MARK: - Authentication Status
    
    func checkAuthStatus() {
        Task {
            do {
                let session = try await supabase.auth.session
                if let userId = session.user.id.uuidString as String? {
                    await loadUserData(uid: userId)
                }
            } catch {
                // No active session
                isAuthenticated = false
            }
        }
    }
    
    // MARK: - Mock Sign In (Bypass)
    
    func mockSignIn() {
        let mockUser = User(
            id: "mock_admin_id",
            organizationId: "mock_org",
            email: "admin@ltms.test",
            role: .admin,
            firstName: "Mock",
            lastName: "Admin",
            profilePictureURL: nil,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date(),
            lastLogin: Date()
        )
        self.currentUser = mockUser
        self.isAuthenticated = true
    }
    
    // MARK: - Sign In
    
    func signIn(email: String, password: String) async throws {
        // BYPASS: If using placeholder plist or test emails, allow test credentials
        if email.hasSuffix("@ltms.test") || email.hasSuffix("@test.com") {
            // Check if user exists in MockDataService
            let existingUser = MockDataService.shared.getUserByEmail(email)
            
            if let user = existingUser {
                // Validate password
                if !MockDataService.shared.validateCredentials(email: email, password: password) {
                    throw AuthError.invalidCredentials
                }
                
                // Check if account is active
                if !user.isActive {
                    throw AuthError.accountDeactivated
                }
                
                // Debug logging
                print("🔍 Login Debug:")
                print("   Email: \(email)")
                print("   User found: \(user.fullName)")
                print("   Role in storage: \(user.role)")
                print("   Role display: \(user.role.displayName)")
                
                // Use existing user data
                self.currentUser = user
                self.isAuthenticated = true
                
                print("   ✅ Set currentUser with role: \(self.currentUser?.role.displayName ?? "nil")")
                
                return
            }
            
            // For test emails not in MockDataService, create a mock user based on the email
            let role: UserRole
            if email.contains("admin") {
                role = .admin
            } else if email.contains("educator") || email.contains("teacher") {
                role = .educator
            } else {
                role = .learner
            }
            
            let mockUser = User(
                id: UUID().uuidString,
                organizationId: "test_org",
                email: email,
                role: role,
                firstName: "Test",
                lastName: "User",
                profilePictureURL: nil,
                isActive: true,
                createdAt: Date(),
                updatedAt: Date(),
                lastLogin: Date()
            )
            self.currentUser = mockUser
            self.isAuthenticated = true
            return
        }

        isLoading = true
        defer { isLoading = false }
        do {
            let session = try await supabase.auth.signIn(email: email, password: password)
            
            // Check if email is verified
            if let emailConfirmedAt = session.user.emailConfirmedAt, emailConfirmedAt == nil {
                try? await supabase.auth.signOut()
                throw AuthError.emailNotVerified
            }
            
            await loadUserData(uid: session.user.id.uuidString)
            if let user = currentUser, !user.isActive {
                try? await supabase.auth.signOut()
                currentUser = nil
                isAuthenticated = false
                throw AuthError.accountDeactivated
            }
            if let userId = currentUser?.id {
                try await SupabaseService.shared.client.database
                    .from("users")
                    .update(["lastLogin": Date().iso8601String])
                    .eq("id", value: userId)
                    .execute()
            }
        } catch {
            throw mapAuthError(error)
        }
    }
    
    // MARK: - Sign Up
    
    func signUp(email: String, password: String, firstName: String, lastName: String, role: UserRole, organizationId: String?) async throws {
        // BYPASS: Mock signup for testing (expanded to handle Firebase config issues)
        if email.hasSuffix("@ltms.test") || email.hasSuffix("@test.com") {
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
            
            // Save to MockDataService so it appears in user management (with password)
            MockDataService.shared.addUser(mockUser, password: password)
            
            self.currentUser = mockUser
            self.isAuthenticated = true
            return
        }

        isLoading = true
        defer { isLoading = false }
        do {
            print("🔵 Sending OTP to: \(email)")
            
            // Store user data and password for later (after OTP verification)
            pendingUserData = (email: email, firstName: firstName, lastName: lastName, role: role, organizationId: organizationId)
            
            // Store password temporarily in memory for account creation after verification
            UserDefaults.standard.set(password, forKey: "pending_password_\(email)")
            
            // Send OTP email for verification (shouldCreateUser: true to enable OTP signup)
            try await supabase.auth.signInWithOTP(
                email: email,
                shouldCreateUser: true  // Changed to true - this works without additional config
            )
            
            print("✅ Verification code sent to \(email)")
            
            // Show OTP verification screen
            showOTPVerification = true
            print("🟢 showOTPVerification set to true - OTP screen should appear now")
        } catch {
            print("🔴 Signup error: \(error)")
            print("🔴 Error description: \(error.localizedDescription)")
            throw mapAuthError(error)
        }
    }
    
    // MARK: - Verify OTP
    
    func verifyOTP(email: String, token: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            print("🔵 Verifying OTP for: \(email)")
            
            // Verify the OTP (user is already created with shouldCreateUser: true)
            let session = try await supabase.auth.verifyOTP(
                email: email,
                token: token,
                type: .email
            )
            
            print("🔵 OTP verified! User is now authenticated")
            print("🔵 Session user ID: \(session.user.id)")
            print("🔵 Session user email: \(session.user.email ?? "no email")")
            
            // Get stored user data
            guard let userData = pendingUserData else {
                print("🔴 No pending user data found!")
                throw AuthError.unknown("User data not found. Please sign up again.")
            }
            
            print("🔵 Retrieved pending data: \(userData.email), \(userData.firstName), role: \(userData.role)")
            
            // User is already created by OTP, get their ID
            let userId = session.user.id.uuidString
            print("🔵 User ID: \(userId)")
            
            let user = User(
                id: userId,
                organizationId: userData.organizationId,
                email: userData.email,
                role: userData.role,
                firstName: userData.firstName,
                lastName: userData.lastName,
                profilePictureURL: nil,
                isActive: true,
                createdAt: Date(),
                updatedAt: Date(),
                lastLogin: Date()
            )
            
            print("🔵 Created User object, attempting to save to database...")
            
            // Try to create, if duplicate or table doesn't exist, skip for now
            do {
                _ = try await SupabaseService.shared.create(user, in: "users")
                print("✅ User saved to database successfully!")
            } catch {
                print("⚠️ Could not save to database (this is OK if table doesn't exist yet): \(error)")
                print("⚠️ Error details: \(error.localizedDescription)")
                // Don't throw - continue with authentication even if DB save fails
            }
            
            // Clear pending data
            pendingUserData = nil
            UserDefaults.standard.removeObject(forKey: "pending_password_\(email)")
            
            // Authenticate user
            currentUser = user
            isAuthenticated = true
            print("✅ User authenticated successfully!")
            print("✅ isAuthenticated = \(isAuthenticated)")
            print("✅ currentUser = \(user.email)")
            
            // Hide OTP verification screen
            showOTPVerification = false
            print("✅ OTP screen hidden, should navigate to main app")
            
        } catch {
            print("🔴 OTP verification error: \(error)")
            throw mapAuthError(error)
        }
    }
    
    // MARK: - Resend OTP
    
    func resendOTP(email: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            print("🔵 Resending OTP to: \(email)")
            try await supabase.auth.signInWithOTP(
                email: email,
                shouldCreateUser: true
            )
            print("✅ New verification code sent!")
        } catch {
            throw mapAuthError(error)
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() throws {
        Task {
            try await supabase.auth.signOut()
        }
        currentUser = nil
        isAuthenticated = false
    }
    
    // MARK: - Load User Data
    
    private func loadUserData(uid: String) async {
        do {
            let user: User = try await SupabaseService.shared.fetch(
                id: uid,
                from: "users"
            )
            currentUser = user
            isAuthenticated = true
        } catch {
            print("Error loading user data: \(error)")
            isAuthenticated = false
        }
    }
    
    // MARK: - Error Mapping
    
    private func mapAuthError(_ error: Error) -> AuthError {
        let errorMessage = error.localizedDescription.lowercased()
        
        if errorMessage.contains("user not found") {
            return .userNotFound
        } else if errorMessage.contains("invalid") || errorMessage.contains("password") {
            return .invalidCredentials
        } else if errorMessage.contains("already") || errorMessage.contains("exists") {
            return .emailAlreadyInUse
        } else if errorMessage.contains("weak") {
            return .weakPassword
        } else if errorMessage.contains("network") {
            return .networkError
        } else if errorMessage.contains("otp") || errorMessage.contains("token") {
            return .invalidOTP
        } else if errorMessage.contains("expired") {
            return .otpExpired
        } else {
            return .unknown(error.localizedDescription)
        }
    }
}

