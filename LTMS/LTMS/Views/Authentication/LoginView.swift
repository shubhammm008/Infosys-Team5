//
//  LoginView.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var authService = SupabaseAuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.dashboardBg
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Logo and Title
                    VStack(spacing: 12) {
                        Image(systemName: "graduationcap.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(Color.accentPrimary)
                        
                        Text("LTMS")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.dashboardTextPrimary)
                        
                        Text("Learning & Training Management System")
                            .font(.subheadline)
                            .foregroundColor(.dashboardTextSecondary)
                    }
                    .padding(.top, 40)
                    
                    // Login Form
                    VStack(spacing: 20) {
                        // Email Field
                        LTMSInputField(
                            title: "Email",
                            icon: "envelope.fill",
                            placeholder: "Enter your email",
                            text: $email,
                            keyboardType: .emailAddress
                        )
                        
                        // Password Field
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
                            .background(Color.accentPrimary)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(authService.isLoading || email.isEmpty || password.isEmpty)
                        .opacity((authService.isLoading || email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                        
                        // Sign Up Link
                        NavigationLink {
                            SignUpView()
                        } label: {
                            Text("Don't have an account? **Sign Up**")
                                .font(.subheadline)
                                .foregroundColor(.accentPrimary)
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                }
            }
            .preferredColorScheme(.dark)
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
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
}

#Preview {
    LoginView()
}
