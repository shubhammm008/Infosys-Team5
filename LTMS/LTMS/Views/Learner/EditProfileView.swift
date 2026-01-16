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
    
    // Photo picker states
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    @State private var profileImage: UIImage?
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dark gradient background
                Rectangle()
                    .fill(Color.dashboardBg)
                    .ignoresSafeArea()
                
                Form {
                // MARK: - Profile Picture Section
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            // Display selected image or default avatar
                            if let profileImage = profileImage {
                                Image(uiImage: profileImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                LinearGradient(
                                                    colors: [.accentBlue, .accentPurple],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 3
                                            )
                                    )
                            } else {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.accentBlue, .accentPurple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 44))
                                            .foregroundColor(.white)
                                    )
                            }
                            
                            // PhotosPicker button
                            PhotosPicker(
                                selection: $selectedPhotoItem,
                                matching: .images,
                                photoLibrary: .shared()
                            ) {
                                HStack(spacing: 6) {
                                    Image(systemName: "camera.fill")
                                        .font(.caption)
                                    Text("Change Photo")
                                }
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.accentBlue)
                            }
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
                
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
            .onChange(of: selectedPhotoItem) { oldValue, newValue in
                print("📸 PhotosPicker selection changed")
                Task {
                    if let newValue = newValue {
                        print("📸 New value exists, attempting to load...")
                        do {
                            if let data = try await newValue.loadTransferable(type: Data.self) {
                                print("📸 Data loaded: \(data.count) bytes")
                                if let uiImage = UIImage(data: data) {
                                    print("📸 UIImage created successfully")
                                    await MainActor.run {
                                        selectedPhotoData = data
                                        profileImage = uiImage
                                        print("✅ Photo updated successfully - profileImage is now set")
                                    }
                                } else {
                                    print("❌ Failed to create UIImage from data")
                                }
                            } else {
                                print("❌ Failed to load transferable data")
                            }
                        } catch {
                            print("❌ Error loading photo: \(error)")
                        }
                    } else {
                        print("📸 New value is nil")
                    }
                }
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
            
            // Load existing profile picture if available
            if let profilePictureURL = user.profilePictureURL,
               let url = URL(string: profilePictureURL) {
                Task {
                    do {
                        let (data, _) = try await URLSession.shared.data(from: url)
                        if let uiImage = UIImage(data: data) {
                            await MainActor.run {
                                profileImage = uiImage
                                selectedPhotoData = data
                                print("✅ Loaded existing profile picture")
                            }
                        }
                    } catch {
                        print("⚠️ Failed to load existing profile picture: \(error)")
                    }
                }
            }
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
                
                // Upload photo if one was selected
                if let photoData = selectedPhotoData {
                    print("📤 Uploading profile photo...")
                    
                    // Create unique filename
                    let fileName = "\(userId)_\(UUID().uuidString).jpg"
                    let path = "profile_pictures/\(fileName)"
                    
                    // Upload to Supabase storage
                    do {
                        try await SupabaseService.shared.client.storage
                            .from("profile-pictures")
                            .upload(
                                path,
                                data: photoData,
                                options: FileOptions(contentType: "image/jpeg", upsert: true)
                            )
                        
                        // Get public URL
                        let publicURL = try SupabaseService.shared.client.storage
                            .from("profile-pictures")
                            .getPublicURL(path: path)
                        
                        updatedUser.profilePictureURL = publicURL.absoluteString
                        print("✅ Photo uploaded successfully: \(publicURL.absoluteString)")
                    } catch {
                        print("⚠️ Failed to upload photo: \(error.localizedDescription)")
                        // Continue without photo upload
                    }
                }
                
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
