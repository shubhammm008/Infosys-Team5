//
//  RoleBasedAuthView.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import SwiftUI

struct RoleBasedAuthView: View {
    let role: UserRole
    @State private var showingSignUp = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Toggle between Login and Sign Up (only for Learners)
            if role == .learner {
                Picker("Auth Mode", selection: $showingSignUp) {
                    Text("Login").tag(false)
                    Text("Sign Up").tag(true)
                }
                .pickerStyle(.segmented)
                .padding()
                .background(Color.ltmsBackground)
            }
            
            // Content
            if showingSignUp && role == .learner {
                RoleBasedSignUpView(role: role)
            } else {
                RoleBasedLoginView(role: role)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Role-Based Login View
struct RoleBasedLoginView: View {
    let role: UserRole
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = SupabaseAuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var roleColor: [Color] {
        switch role {
        case .educator:
            return [.ltmsPrimary, .ltmsSecondary]
        case .learner:
            return [.green, .teal]
        case .admin:
            return [.purple, .purple.opacity(0.7)]
        }
    }
    
    var roleIcon: String {
        switch role {
        case .educator:
            return "person.fill.checkmark"
        case .learner:
            return "person.fill.viewfinder"
        case .admin:
            return "person.badge.key.fill"
        }
    }
    
    var body: some View {
        ZStack {
            Color.ltmsBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Logo and Title
                    VStack(spacing: 12) {
                        Image(systemName: roleIcon)
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: roleColor,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("\(role.displayName) Login")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Welcome back!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Login Form
                    VStack(spacing: 20) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.secondary)
                                TextField("Enter your email", text: $email)
                                    .textContentType(.emailAddress)
                                    .autocapitalization(.none)
                                    .keyboardType(.emailAddress)
                            }
                            .padding()
                            .background(Color.ltmsCardBackground)
                            .cornerRadius(12)
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.secondary)
                                SecureField("Enter your password", text: $password)
                                    .textContentType(.password)
                            }
                            .padding()
                            .background(Color.ltmsCardBackground)
                            .cornerRadius(12)
                        }
                        
                        // Login Button
                        Button(action: handleLogin) {
                            HStack {
                                if authService.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Sign In")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: roleColor,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(authService.isLoading || email.isEmpty || password.isEmpty)
                        .opacity((authService.isLoading || email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                        
                        // Educator-specific info
                        if role == .educator {
                            HStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.orange)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Educator Access")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    Text("Educator accounts are created by administrators only")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func handleLogin() {
        Task {
            do {
                try await authService.signIn(email: email, password: password)
                // Verify that the user has the correct role
                if let user = authService.currentUser, user.role != role {
                    try? await authService.signOut()
                    errorMessage = "This account is registered as a \(user.role.displayName). Please use the correct login option."
                    showError = true
                } else {
                    dismiss()
                }
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Role-Based Sign Up View
struct RoleBasedSignUpView: View {
    let role: UserRole
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = SupabaseAuthService.shared
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showOTPView = false
    @State private var isCheckingEmail = false
    
    var roleColor: [Color] {
        switch role {
        case .educator:
            return [.ltmsPrimary, .ltmsSecondary]
        case .learner:
            return [.green, .teal]
        case .admin:
            return [.purple, .purple.opacity(0.7)]
        }
    }
    
    var roleIcon: String {
        switch role {
        case .educator:
            return "person.fill.checkmark"
        case .learner:
            return "person.fill.viewfinder"
        case .admin:
            return "person.badge.key.fill"
        }
    }
    
    var body: some View {
        if showOTPView {
            OTPVerificationView(
                email: email,
                userData: PendingUserData(
                    firstName: firstName,
                    lastName: lastName,
                    role: role,
                    password: password
                )
            ) {
                // On successful verification
                print("✅ OTP verified, dismissing signup")
                dismiss()
            }
        } else {
            ZStack {
                Color.ltmsBackground
                    .ignoresSafeArea()
                
                ScrollView {
                VStack(spacing: 25) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: roleIcon)
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: roleColor,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Create \(role.displayName) Account")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        
                        Text("Join LTMS as a \(role.displayName)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Form
                    VStack(spacing: 18) {
                        // Name Fields
                        HStack(spacing: 12) {
                            FormField(
                                title: "First Name",
                                icon: "person.fill",
                                placeholder: "John",
                                text: $firstName
                            )
                            
                            FormField(
                                title: "Last Name",
                                icon: "person.fill",
                                placeholder: "Doe",
                                text: $lastName
                            )
                        }
                        
                        // Email
                        FormField(
                            title: "Email",
                            icon: "envelope.fill",
                            placeholder: "john.doe@example.com",
                            text: $email,
                            keyboardType: .emailAddress
                        )
                        
                        // Password
                        SecureFormField(
                            title: "Password",
                            icon: "lock.fill",
                            placeholder: "At least 6 characters",
                            text: $password
                        )
                        
                        // Confirm Password
                        SecureFormField(
                            title: "Confirm Password",
                            icon: "lock.fill",
                            placeholder: "Re-enter password",
                            text: $confirmPassword
                        )
                        
                        // Testing Info Banner
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Testing Mode")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                Text("Use an email ending with @test.com for testing")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                        
                        // Sign Up Button
                        Button(action: handleSignUp) {
                            HStack {
                                if authService.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Create Account")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: roleColor,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(!isFormValid || authService.isLoading)
                        .opacity((!isFormValid || authService.isLoading) ? 0.6 : 1.0)
                    }
                    .padding(.horizontal, 30)
                }
                .padding(.bottom, 30)
            }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        // Temporarily simplified for testing
        true
    }
    
    private func handleSignUp() {
        print("🔵 Create Account clicked - showing OTP screen")
        showOTPView = true
    }
}

#Preview {
    NavigationStack {
        RoleBasedAuthView(role: .educator)
    }
}
