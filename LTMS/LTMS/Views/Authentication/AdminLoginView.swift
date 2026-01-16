//
//  AdminLoginView.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import SwiftUI

struct AdminLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = SupabaseAuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            Color.dashboardBg
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Logo and Title
                VStack(spacing: 12) {
                    Image(systemName: "person.badge.key.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(Color.accentPrimary)
                    
                    Text("Admin Login")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.dashboardTextPrimary)
                    
                    Text("Access administrative controls")
                        .font(.subheadline)
                        .foregroundColor(.dashboardTextSecondary)
                }
                .padding(.top, 40)
                
                // Login Form
                VStack(spacing: 20) {
                    LTMSInputField(
                        title: "Admin Email",
                        icon: "envelope.fill",
                        placeholder: "Enter admin email",
                        text: $email,
                        keyboardType: .emailAddress
                    )
                    
                    LTMSInputField(
                        title: "Password",
                        icon: "lock.fill",
                        placeholder: "Enter password",
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
                                Image(systemName: "key.fill")
                                Text("Sign In as Admin")
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
                    
                    // Note about admin access
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.accentWarning)
                        Text("Admin accounts are created by system administrators only")
                            .font(.caption)
                            .foregroundColor(.dashboardTextSecondary)
                    }
                    .padding()
                    .background(Color.accentWarning.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
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
                // Verify that the user is actually an admin
                if let user = authService.currentUser, user.role != .admin {
                    try? await authService.signOut()
                    errorMessage = "This account is not an admin account. Please use the appropriate login option."
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

#Preview {
    NavigationStack {
        AdminLoginView()
    }
}
