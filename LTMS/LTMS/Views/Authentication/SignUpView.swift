//
//  SignUpView.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = SupabaseAuthService.shared
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var selectedRole: UserRole = .learner
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showOTPView = false
    @State private var isCheckingEmail = false
    
    var body: some View {
        if showOTPView {
            OTPVerificationView(
                email: email,
                userData: PendingUserData(
                    firstName: firstName,
                    lastName: lastName,
                    role: selectedRole,
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
                        Image(systemName: "person.badge.plus.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.accentPrimary)
                        
                        Text("Create Account")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.dashboardTextPrimary)
                        
                        Text("Join LTMS today")
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
                        
                        // Role Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Role")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.dashboardTextSecondary)
                            
                            Picker("Role", selection: $selectedRole) {
                                ForEach(UserRole.allCases, id: \.self) { role in
                                    Text(role.displayName).tag(role)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        
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
                        
                        // Sign Up Button
                        Button {
                            print("🔵 CREATE ACCOUNT BUTTON CLICKED")
                            showOTPView = true
                        } label: {
                            HStack {
                                if isCheckingEmail || authService.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Create Account")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentPrimary)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(!isFormValid || isCheckingEmail || authService.isLoading)
                        .opacity((!isFormValid || isCheckingEmail || authService.isLoading) ? 0.6 : 1.0)
                    }
                    .padding(.horizontal, 30)
                }
                .padding(.bottom, 30)
            }
            }
            .preferredColorScheme(.dark)
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        password == confirmPassword &&
        password.count >= AppConstants.minimumPasswordLength &&
        email.isValidEmail
    }
    
    private func handleSignUp() {
        print("🔵 SignUpView: Create Account clicked - showing OTP screen")
        showOTPView = true
    }
}


// MARK: - Form Field Components



#Preview {
    NavigationStack {
        SignUpView()
    }
}
