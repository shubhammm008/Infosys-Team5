//
//  UnifiedAuthView.swift
//  LTMS
//
//  Created by Shubham Singh on 08/01/26.
//

import SwiftUI

struct UnifiedAuthView: View {
    @StateObject private var authService = SupabaseAuthService.shared
    @State private var showingSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showOTPView = false
    
    var body: some View {
        if showOTPView {
            OTPVerificationView(
                email: email,
                userData: PendingUserData(
                    firstName: firstName,
                    lastName: lastName,
                    role: .learner,
                    password: password
                )
            ) {
                // On successful verification - user is logged in
                print("✅ OTP verified successfully")
            }
        } else {
        NavigationStack {
            ZStack {
                Color.dashboardBg
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Logo and Title
                        VStack(spacing: 12) {
                            Image(systemName: "graduationcap.circle.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(Color.accentPrimary)
                            
                            Text("LTMS")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.dashboardTextPrimary)
                            
                            Text("Learning & Training Management")
                                .font(.subheadline)
                                .foregroundColor(.dashboardTextSecondary)
                        }
                        .padding(.top, 40)
                        
                        // Toggle between Login and Sign Up
//                        Picker("Auth Mode", selection: $showingSignUp) {
//                            Text("Login").tag(false)
//                            Text("Sign Up").tag(true)
//                        }
//                        .pickerStyle(.segmented)
//                        .padding(.horizontal, 30)

                        
                        // Form
                        VStack(spacing: 20) {
                            if showingSignUp {
                                // Sign Up Form
                                signUpForm
                            } else {
                                // Login Form
                                loginForm
                            }
                        }
                        .padding(.horizontal, 30)
                        authModeSwitch
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
        }
    }
    
    // MARK: - Login Form
    
    private var loginForm: some View {
        VStack(spacing: 20) {
            // Email
            LTMSInputField(
                title: "Email",
                icon: "envelope.fill",
                placeholder: "Enter your email",
                text: $email
            )
            
            // Password
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
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Sign In")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentPrimary)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(authService.isLoading || email.isEmpty || password.isEmpty)
            .opacity((authService.isLoading || email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
        }
    }
    
    // MARK: - Sign Up Form
    
    private var signUpForm: some View {
        VStack(spacing: 20) {
            // First Name
            LTMSInputField(
                title: "First Name",
                icon: "person.fill",
                placeholder: "Enter your first name",
                text: $firstName
            )
            
            // Last Name
            LTMSInputField(
                title: "Last Name",
                icon: "person.fill",
                placeholder: "Enter your last name",
                text: $lastName
            )
            
            // Email
            LTMSInputField(
                title: "Email",
                icon: "envelope.fill",
                placeholder: "Enter your email",
                text: $email
            )
            
            // Email validation feedback
            if !email.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: email.isValidEmail ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(email.isValidEmail ? .green : .red)
                    Text(email.isValidEmail ? "Valid email" : "Invalid email format")
                        .font(.caption)
                        .foregroundColor(email.isValidEmail ? .green : .red)
                    Spacer()
                }
                .padding(.horizontal, 4)
            }
            
            // Password
            LTMSInputField(
                title: "Password",
                icon: "lock.fill",
                placeholder: "Minimum \(AppConstants.minimumPasswordLength) characters",
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
            
            // Password match feedback
            if !confirmPassword.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: password == confirmPassword ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(password == confirmPassword ? .green : .red)
                    Text(password == confirmPassword ? "Passwords match" : "Passwords don't match")
                        .font(.caption)
                        .foregroundColor(password == confirmPassword ? .green : .red)
                    Spacer()
                }
                .padding(.horizontal, 4)
            }
            
            // Info Banner
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.accentPrimary)
                VStack(alignment: .leading, spacing: 4) {
                    Text("New User Registration")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.dashboardTextPrimary)
                    Text("All new accounts start as Learners. Contact admin for role changes.")
                        .font(.caption2)
                        .foregroundColor(.dashboardTextSecondary)
                }
                Spacer()
            }
            .padding()
            .background(Color.accentPrimary.opacity(0.1))
            .cornerRadius(10)
            
            // Sign Up Button - Green when valid
            Button(action: handleSignUp) {
                HStack {
                    if authService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        if isFormValid {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text("Create Account")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    isFormValid ?
                    Color.accentPrimary :
                    Color.gray.opacity(0.3)
                )
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(authService.isLoading || !isFormValid)
            .animation(.easeInOut(duration: 0.3), value: isFormValid)
        }
    }
    
    // MARK: - Validation
    
    private var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        password.count >= AppConstants.minimumPasswordLength &&
        password == confirmPassword &&
        email.isValidEmail
    }
    
    // MARK: - Actions
    
    private func handleLogin() {
        Task {
            do {
                try await authService.signIn(email: email, password: password)
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func handleSignUp() {
        print("🔵 UnifiedAuthView: Create Account clicked - showing OTP screen")
        showOTPView = true
    }
    // MARK: - Apple-style Auth Mode Switch

    private var authModeSwitch: some View {
        HStack(spacing: 6) {
            if showingSignUp {
                Text("Already have an account?")
                    .foregroundColor(.dashboardTextSecondary)

                Button {
                    withAnimation(.easeInOut) {
                        showingSignUp = false
                    }
                } label: {
                    Text("Sign In")
                        .fontWeight(.semibold)
                        .foregroundColor(.accentPrimary)
                }
            } else {
                Text("Don’t have an account?")
                    .foregroundColor(.dashboardTextSecondary)

                Button {
                    withAnimation(.easeInOut) {
                        showingSignUp = true
                    }
                } label: {
                    Text("Sign Up")
                        .fontWeight(.semibold)
                        .foregroundColor(.accentPrimary)
                }
            }
        }
        .font(.subheadline)
        .padding(.top, 10)
    }

}

#Preview {
    UnifiedAuthView()
}
