import SwiftUI




struct CreateUserView: View {

    @Environment(\.dismiss) private var dismiss

    

    @State private var email = ""

    @State private var firstName = ""

    @State private var lastName = ""

    @State private var selectedRole: UserRole = .educator

    

    @State private var generatedPassword = ""

    

    @State private var isLoading = false

    @State private var showError = false

    @State private var errorMessage = ""

    

    @State private var showSuccess = false

    

    var body: some View {

        NavigationStack {

            Form {

                

                            

                // MARK: - Personal Information

                Section("Personal Information") {

                    TextField("First Name", text: $firstName)

                    TextField("Last Name", text: $lastName)

                    

                    TextField("Email", text: $email)

                        .textContentType(.emailAddress)

                        .keyboardType(.emailAddress)

                        .autocapitalization(.none)

                }

                

                // MARK: - Account Details

                Section("Account Details") {

                    HStack {

                        Text("Role")

                        Spacer()

                        Text("Educator")

                            .foregroundColor(.dashboardTextSecondary)

                    }

                    

                    HStack {

                        Text("Password")

                        Spacer()

                        Text("Auto-generated")

                            .foregroundColor(.dashboardTextSecondary)

                    }

                    

                    Text("A secure password will be generated automatically and emailed to the educator.")

                        .font(.caption)

                        .foregroundColor(.dashboardTextSecondary)

                }

                

                // MARK: - Create Button

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

                

            }

            .navigationTitle("Create Educator")

            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(Color.dashboardBg)

            .toolbar {

                ToolbarItem(placement: .cancellationAction) {

                    Button("Cancel") {

                        dismiss()

                    }

                }

            }

            // MARK: - Error Alert

            .alert("Error", isPresented: $showError) {

                Button("OK", role: .cancel) {}

            } message: {

                Text(errorMessage)

            }

            // MARK: - Success Alert

            .alert("Educator Created", isPresented: $showSuccess) {

                Button("Done") {

                    dismiss()

                }

            } message: {

                Text("Login credentials have been successfully sent to \(email).")

            }

        }

    }

    

    // MARK: - Validation

    private var isFormValid: Bool {

        !firstName.isEmpty &&

        !lastName.isEmpty &&

        email.isValidEmail

    }

    

    // MARK: - Create User

    private func createUser() {

        Task {

            isLoading = true

            defer { isLoading = false }

            

            do {

                let emailExists = try await SupabaseAuthService.shared.checkEmailExists(email: email)




                            if emailExists {

                                errorMessage = "An account with this email already exists."

                                showError = true

                                return

                            }

                generatedPassword = generateSecurePassword()

                

                try await SupabaseAuthService.shared.createUserByAdmin(

                    email: email,

                    password: generatedPassword,

                    firstName: firstName,

                    lastName: lastName,

                    role: selectedRole,

                    organizationId: AppConstants.defaultOrganizationId

                )

                

                // Assume backend/email service sends credentials

                showSuccess = true

                

            } catch {

                errorMessage = error.localizedDescription

                showError = true

            }

        }

    }

    

    // MARK: - Secure Password Generator

    private func generateSecurePassword() -> String {

        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789@#$%"

        return String((0..<12).compactMap { _ in characters.randomElement() })

    }

}







#Preview {

    CreateUserView()

}
