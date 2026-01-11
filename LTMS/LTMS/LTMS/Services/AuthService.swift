//
//  AuthService.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

enum AuthError: LocalizedError {
    case userNotFound
    case invalidCredentials
    case emailAlreadyInUse
    case weakPassword
    case networkError
    case accountDeactivated
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
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    private init() {
        checkAuthStatus()
    }
    
    // MARK: - Authentication Status
    
    func checkAuthStatus() {
        if let firebaseUser = auth.currentUser {
            Task {
                await loadUserData(uid: firebaseUser.uid)
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
            
            // User not found in MockDataService - they need to sign up first
            print("❌ User not found: \(email)")
            throw AuthError.userNotFound
        }

        isLoading = true
        defer { isLoading = false }
        
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            await loadUserData(uid: result.user.uid)
            
            // Check if account is active
            if let user = currentUser, !user.isActive {
                try? auth.signOut()
                currentUser = nil
                isAuthenticated = false
                throw AuthError.accountDeactivated
            }
            
            // Update last login
            if let userId = currentUser?.id {
                try await db.collection(FirebaseConstants.users)
                    .document(userId)
                    .updateData(["lastLogin": Date()])
            }
        } catch let error as NSError {
            throw mapAuthError(error)
        }
    }
    
    // MARK: - Sign Up
    
    // MARK: - Sign Up
    
    func signUp(email: String, password: String, firstName: String, lastName: String, role: UserRole, organizationId: String) async throws {
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
            print("🔵 Starting signup for: \(email)")
            let result = try await auth.createUser(withEmail: email, password: password)
            print("🔵 Firebase user created: \(result.user.uid)")
            
            // Create user document in Firestore
            let user = User(
                id: result.user.uid,
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
            
            print("🔵 Saving user to Firestore...")
            try db.collection(FirebaseConstants.users)
                .document(result.user.uid)
                .setData(from: user)
            
            print("🔵 User saved successfully!")
            currentUser = user
            isAuthenticated = true
        } catch let error as NSError {
            print("🔴 Signup error: \(error)")
            print("🔴 Error code: \(error.code)")
            print("🔴 Error domain: \(error.domain)")
            print("🔴 Error description: \(error.localizedDescription)")
            
            // Check if this is a Firebase configuration error
            if error.domain == "FIRAuthErrorDomain" && error.code == 17999 {
                throw AuthError.unknown("Firebase is not configured. Please use an email ending with @test.com for testing.")
            }
            
            throw mapAuthError(error)
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() throws {
        try auth.signOut()
        currentUser = nil
        isAuthenticated = false
    }
    
    // MARK: - Load User Data
    
    private func loadUserData(uid: String) async {
        do {
            let user: User = try await FirebaseService.shared.fetch(
                id: uid,
                from: FirebaseConstants.users
            )
            currentUser = user
            isAuthenticated = true
        } catch {
            print("Error loading user data: \(error)")
            isAuthenticated = false
        }
    }
    
    // MARK: - Error Mapping
    
    private func mapAuthError(_ error: NSError) -> AuthError {
        let errorCode = AuthErrorCode(rawValue: error.code)
        
        switch errorCode {
        case .userNotFound:
            return .userNotFound
        case .wrongPassword, .invalidCredential:
            return .invalidCredentials
        case .emailAlreadyInUse:
            return .emailAlreadyInUse
        case .weakPassword:
            return .weakPassword
        case .networkError:
            return .networkError
        default:
            return .unknown(error.localizedDescription)
        }
    }
}

