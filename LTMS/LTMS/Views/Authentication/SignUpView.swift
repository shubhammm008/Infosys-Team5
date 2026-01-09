//
//  SignUpView.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var authService = AuthService.shared
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var selectedRole: UserRole = .learner
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var navigateToOTP = false
    
    var body: some View {
        ZStack {
            Color.ltmsBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.badge.plus.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.ltmsPrimary, .ltmsSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Create Account")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        
                        Text("Join LTMS today")
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
                        
                        // Role Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Role")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            Picker("Role", selection: $selectedRole) {
                                ForEach(UserRole.allCases, id: \.self) { role in
                                    Text(role.displayName).tag(role)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        
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
                        
                        // Sign Up Button
                        Button(action: {
                            print("🔴🔴🔴 BUTTON CLICKED!")
                            print("🔴 Form valid: \(isFormValid)")
                            print("🔴 Loading: \(authService.isLoading)")
                            print("🔴 Current showOTPVerification: \(authService.showOTPVerification)")
                            handleSignUp()
                        }) {
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
                                    colors: [.ltmsPrimary, .ltmsSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(!isFormValid || authService.isLoading)
                        .opacity((!isFormValid || authService.isLoading) ? 0.6 : 1.0)

                        // Hidden navigation link to OTP screen
                        NavigationLink(
                            destination: OTPVerificationView(email: email),
                            isActive: $navigateToOTP
                        ) {
                            EmptyView()
                        }
                        .hidden()
                        
                        // DEBUG: Test button to verify fullScreenCover works
                        Button("TEST OTP SCREEN (Debug)") {
                            print("🟣 TEST: Setting showOTPVerification to true")
                            authService.showOTPVerification = true
                            print("🟣 TEST: Value is now: \(authService.showOTPVerification)")
                        }
                        .foregroundColor(.purple)
                        
                        // Validation feedback
                        if !isFormValid {
                            VStack(alignment: .leading, spacing: 4) {
                                if email.isEmpty || !email.isValidEmail {
                                    Text("• Please enter a valid email address")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                                if password.isEmpty || password.count < AppConstants.minimumPasswordLength {
                                    Text("• Password must be at least \(AppConstants.minimumPasswordLength) characters")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                                if password != confirmPassword && !confirmPassword.isEmpty {
                                    Text("• Passwords do not match")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                                if firstName.isEmpty {
                                    Text("• First name is required")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                                if lastName.isEmpty {
                                    Text("• Last name is required")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.horizontal, 30)
                }
                .padding(.bottom, 30)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private var isFormValid: Bool {
        let valid = !email.isEmpty &&
        !password.isEmpty &&
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        password == confirmPassword &&
        password.count >= AppConstants.minimumPasswordLength &&
        email.isValidEmail
        
        // Debug logging
        print("📋 Form validation check:")
        print("   Email valid: \(email.isValidEmail) [\(email)]")
        print("   Password length: \(password.count) (min: \(AppConstants.minimumPasswordLength))")
        print("   Passwords match: \(password == confirmPassword)")
        print("   First name: \(!firstName.isEmpty)")
        print("   Last name: \(!lastName.isEmpty)")
        print("   Overall valid: \(valid)")
        
        return valid
    }
    
    private func handleSignUp() {
        print("🟢 handleSignUp() called - starting signup process")
        // Immediately navigate to OTP screen so user always sees it
        navigateToOTP = true
        Task {
            do {
                print("🟢 Starting signup...")
                try await authService.signUp(
                    email: email,
                    password: password,
                    firstName: firstName,
                    lastName: lastName,
                    role: selectedRole,
                    organizationId: nil
                )
                print("🟢 Signup completed successfully - OTP screen should show now")
            } catch {
                print("🔴 Signup failed: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Form Field Components

struct FormField: View {
    let title: String
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .autocapitalization(keyboardType == .emailAddress ? .none : .words)
            }
            .padding()
            .background(Color.ltmsCardBackground)
            .cornerRadius(12)
        }
    }
}

struct SecureFormField: View {
    let title: String
    let icon: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                SecureField(placeholder, text: $text)
            }
            .padding()
            .background(Color.ltmsCardBackground)
            .cornerRadius(12)
        }
    }
}

#Preview {
    NavigationStack {
        SignUpView()
    }
}
