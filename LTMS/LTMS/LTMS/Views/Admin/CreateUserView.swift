//
//  CreateUserView.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import SwiftUI

struct CreateUserView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var selectedRole: UserRole = .educator // Default to educator
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showCredentials = false
    @State private var createdEmail = ""
    @State private var createdPassword = ""
    @State private var createdName = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Create Educator Account")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("Educators can create and manage courses")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Personal Information") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                }
                
                Section("Account Details") {
                    // Role is fixed to Educator only
                    HStack {
                        Text("Role")
                        Spacer()
                        Text("Educator")
                            .foregroundColor(.secondary)
                    }
                    
                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                    
                    Text("Minimum 6 characters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section {
                    Button(action: createUser) {
                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            Text("Create Educator Account")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isLoading || !isFormValid)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Account Access", systemImage: "key.fill")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("After creation, you'll receive the login credentials to share with the educator.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Create Educator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showCredentials) {
                CredentialsDisplayView(
                    name: createdName,
                    email: createdEmail,
                    password: createdPassword,
                    onDismiss: {
                        showCredentials = false
                        dismiss()
                    }
                )
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        password.count >= AppConstants.minimumPasswordLength &&
        email.isValidEmailFormat  // Use flexible validation for admin-created users
    }
    
    private func createUser() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                // Store credentials for display
                createdEmail = email
                createdPassword = password
                createdName = "\(firstName) \(lastName)"
                
                // Create user via Supabase
                try await SupabaseAuthService.shared.signUp(
                    email: email,
                    password: password,
                    firstName: firstName,
                    lastName: lastName,
                    role: .educator,
                    organizationId: AppConstants.defaultOrganizationId
                )
                
                print("✅ Educator created in Supabase: \(email)")
                
                // Show credentials
                showCredentials = true
            } catch {
                print("❌ Error creating educator: \(error)")
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Credentials Display View
struct CredentialsDisplayView: View {
    let name: String
    let email: String
    let password: String
    let onDismiss: () -> Void
    
    @State private var emailCopied = false
    @State private var passwordCopied = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Success Icon
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 8) {
                        Text("Educator Account Created!")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Share these credentials with \(name)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Credentials Card
                    VStack(spacing: 0) {
                        // Name
                        CredentialRow(
                            icon: "person.fill",
                            label: "Name",
                            value: name,
                            showCopy: false
                        )
                        
                        Divider()
                            .padding(.leading, 50)
                        
                        // Email
                        CredentialRow(
                            icon: "envelope.fill",
                            label: "Email",
                            value: email,
                            showCopy: true,
                            isCopied: emailCopied,
                            onCopy: {
                                UIPasteboard.general.string = email
                                emailCopied = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    emailCopied = false
                                }
                            }
                        )
                        
                        Divider()
                            .padding(.leading, 50)
                        
                        // Password
                        CredentialRow(
                            icon: "lock.fill",
                            label: "Password",
                            value: password,
                            showCopy: true,
                            isCopied: passwordCopied,
                            onCopy: {
                                UIPasteboard.general.string = password
                                passwordCopied = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    passwordCopied = false
                                }
                            }
                        )
                    }
                    .background(Color.ltmsCardBackground)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Important Note
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Important")
                                .font(.headline)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Save these credentials securely")
                            Text("• Share them with the educator via secure channel")
                            Text("• The educator should change their password after first login")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Done Button
                    Button(action: onDismiss) {
                        Text("Done")
                            .fontWeight(.semibold)
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
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .background(Color.ltmsBackground)
            .navigationTitle("Login Credentials")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Credential Row Component
struct CredentialRow: View {
    let icon: String
    let label: String
    let value: String
    var showCopy: Bool = false
    var isCopied: Bool = false
    var onCopy: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.ltmsPrimary)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            if showCopy {
                Button(action: { onCopy?() }) {
                    HStack(spacing: 4) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        Text(isCopied ? "Copied" : "Copy")
                            .font(.caption)
                    }
                    .foregroundColor(isCopied ? .green : .ltmsPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isCopied ? Color.green.opacity(0.1) : Color.ltmsPrimary.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
    }
}

#Preview {
    CreateUserView()
}
