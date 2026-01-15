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
                .background(Color.dashboardBg)
            }
            
            // Content
            if showingSignUp && role == .learner {
                RoleBasedSignUpView(role: role)
            } else {
                RoleBasedLoginView(role: role)
            }
        }
        .preferredColorScheme(.dark)
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
            return [Color.accentPrimary, Color.accentPrimary.opacity(0.8)]
        case .learner:
            return [Color.accentSuccess, Color.accentSuccess.opacity(0.8)]
        case .admin:
            return [Color.accentSecondary, Color.accentSecondary.opacity(0.8)]
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
            Color.dashboardBg
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
                            .foregroundColor(.dashboardTextPrimary)
                        
                        Text("Welcome back!")
                            .font(.subheadline)
                            .foregroundColor(.dashboardTextSecondary)
                    }
                    .padding(.top, 40)
                    
                    // Login Form
                    VStack(spacing: 20) {
                        LTMSInputField(
                            title: "Email",
                            icon: "envelope.fill",
                            placeholder: "Enter your email",
                            text: $email,
                            keyboardType: .emailAddress
                        )
                        
                        LTMSInputField(
                            title: "Password",
                            icon: "lock.fill",
                            placeholder: "Enter your password",
                            text: $password,
                            isSecure: true
                        )
                        
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
                                    .foregroundColor(.accentWarning)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Educator Access")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.dashboardTextPrimary)
                                    Text("Educator accounts are created by administrators only")
                                        .font(.caption2)
                                        .foregroundColor(.dashboardTextSecondary)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color.accentWarning.opacity(0.1))
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
                Color.dashboardBg
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
                            .foregroundColor(.dashboardTextPrimary)
                        
                        Text("Join LTMS as a \(role.displayName)")
                            .font(.subheadline)
                            .foregroundColor(.dashboardTextSecondary)
                    }
                    .padding(.top, 20)
                    
                    // Form
                    VStack(spacing: 18) {
                        // Name Fields
                        HStack(spacing: 12) {
                            LTMSInputField(
                                title: "First Name",
                                icon: "person.fill",
                                placeholder: "John",
                                text: $firstName
                            )
                            
                            LTMSInputField(
                                title: "Last Name",
                                icon: "person.fill",
                                placeholder: "Doe",
                                text: $lastName
                            )
                        }
                        
                        // Email
                        LTMSInputField(
                            title: "Email",
                            icon: "envelope.fill",
                            placeholder: "john.doe@example.com",
                            text: $email,
                            keyboardType: .emailAddress
                        )
                        
                        // Password
                        LTMSInputField(
                            title: "Password",
                            icon: "lock.fill",
                            placeholder: "At least 6 characters",
                            text: $password,
                            isSecure: true
                        )
                        
                        // Confirm Password
                        LTMSInputField(
                            title: "Confirm Password",
                            icon: "lock.fill",
                            placeholder: "Re-enter password",
                            text: $confirmPassword,
                            isSecure: true
                        )
                        
                        // Testing Info Banner
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.accentPrimary)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Testing Mode")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.dashboardTextPrimary)
                                Text("Use an email ending with @test.com for testing")
                                    .font(.caption2)
                                    .foregroundColor(.dashboardTextSecondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.accentPrimary.opacity(0.1))
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
