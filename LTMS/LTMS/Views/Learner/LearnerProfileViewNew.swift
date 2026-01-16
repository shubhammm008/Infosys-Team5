//
//  LearnerProfileViewNew.swift
//  LTMS
//

import SwiftUI

struct LearnerProfileViewNew: View {
    @StateObject private var authService = SupabaseAuthService.shared
    @State private var showLogoutAlert = false
    @State private var showEditProfile = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Profile Header Card
                    VStack(spacing: 16) {
                        // Avatar
                        if let profilePictureURL = authService.currentUser?.profilePictureURL,
                           let url = URL(string: profilePictureURL) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(width: 90, height: 90)
                                        .tint(.accentPrimary)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 90, height: 90)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(
                                                    LinearGradient(
                                                        colors: [.accentPrimary, .accentSecondary],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    ),
                                                    lineWidth: 3
                                                )
                                        )
                                case .failure(_):
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [.accentPrimary, .accentSecondary],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 90, height: 90)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 40))
                                                .foregroundColor(.white)
                                        )
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .id(profilePictureURL)
                        } else {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.accentPrimary, .accentSecondary],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 90, height: 90)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white)
                                )
                        }
                        
                        // User Info
                        VStack(spacing: 4) {
                            Text(authService.currentUser?.fullName ?? "User")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.dashboardTextPrimary)
                            
                            Text(authService.currentUser?.email ?? "user@example.com")
                                .font(.subheadline)
                                .foregroundColor(.dashboardTextSecondary)
                        }
                        
                        // Edit Profile Button
                        Button(action: {
                            showEditProfile = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "pencil")
                                    .font(.subheadline)
                                Text("Edit Profile")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [.accentPrimary, .accentSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(14)
                        }
                    }
                    .padding(28)
                    .background(Color.dashboardCard)
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 4)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    // MARK: - Terms & Privacy Section
                    NavigationLink(destination: TermsPrivacyView()) {
                        HStack(spacing: 16) {
                            // Icon with background
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.accentPrimary.opacity(0.2))
                                    .frame(width: 48, height: 48)
                                
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.accentPrimary)
                            }
                            
                            // Title & Subtitle
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Terms & Privacy Policy")
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.dashboardTextPrimary)
                                
                                Text("Review our policies")
                                    .font(.caption)
                                    .foregroundColor(.dashboardTextSecondary)
                            }
                            
                            Spacer()
                            
                            // Chevron
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.dashboardTextSecondary)
                        }
                        .padding(16)
                        .background(Color.dashboardCard)
                        .cornerRadius(16)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    
                    // MARK: - Sign Out Button
                    Button(action: {
                        showLogoutAlert = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.body)
                            Text("Sign Out")
                                .font(.body)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.dashboardCard)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1.5)
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
            .background(Color.dashboardBg)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
            }
            .alert("Sign Out", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    Task {
                        try? await authService.signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}

#Preview {
    LearnerProfileViewNew()
}
