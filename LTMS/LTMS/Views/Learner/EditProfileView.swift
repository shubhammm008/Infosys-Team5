//
//  EditProfileView.swift
//  LTMS
//
//  Created by Assistant on 15/01/26.
//

import SwiftUI
import PhotosUI
import Supabase
import Storage

struct EditProfileView: View {
    @StateObject private var authService = SupabaseAuthService.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    
    @State private var isLoading = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dark gradient background
                Rectangle()
                    .fill(Color.dashboardBg)
                    .ignoresSafeArea()
                
                Form {
                // MARK: - Personal Information
                Section {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.accentBlue)
                            .frame(width: 24)
                        TextField("First Name", text: $firstName)
                            .foregroundColor(.dashboardTextPrimary)
                    }
                    .listRowBackground(Color.dashboardCard)
                    
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.accentPurple)
                            .frame(width: 24)
                        TextField("Last Name", text: $lastName)
                            .foregroundColor(.dashboardTextPrimary)
                    }
                    .listRowBackground(Color.dashboardCard)
                    
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.dashboardTextSecondary)
                            .frame(width: 24)
                        Text(email)
                            .foregroundColor(.dashboardTextSecondary)
                    }
                    .listRowBackground(Color.dashboardCard)
                }
                
                // MARK: - Account Type
                Section {
                    HStack {
                        Image(systemName: "person.badge.shield.checkmark.fill")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        Text("Role")
                            .foregroundColor(.dashboardTextSecondary)
                        Spacer()
                        Text(authService.currentUser?.role.displayName ?? "Learner")
                            .foregroundColor(.dashboardTextPrimary)
                            .fontWeight(.medium)
                    }
                    .listRowBackground(Color.dashboardCard)
                }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.dashboardCard, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.dashboardTextPrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.accentBlue)
                    .disabled(isLoading)
                }
            }
            .onAppear {
                loadCurrentUserData()
            }
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your profile has been updated successfully.")
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.2)
                            .ignoresSafeArea()
                        
                        ProgressView()
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func loadCurrentUserData() {
        if let user = authService.currentUser {
            firstName = user.firstName
            lastName = user.lastName
            email = user.email
        }
    }
    
    private func saveProfile() {
        guard !firstName.isEmpty, !lastName.isEmpty else {
            errorMessage = "First name and last name are required"
            showErrorAlert = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                // Update user in Supabase
                guard let userId = authService.currentUser?.id else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found"])
                }
                
                // Create updated user object
                var updatedUser = authService.currentUser!
                updatedUser.firstName = firstName
                updatedUser.lastName = lastName
                
                // Update in Supabase using correct parameter order
                let result: User = try await SupabaseService.shared.update(
                    updatedUser,
                    id: userId,
                    in: SupabaseConstants.users
                )
                
                // Update local auth service
                await MainActor.run {
                    authService.currentUser = result
                    isLoading = false
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
}

#Preview {
    EditProfileView()
}
