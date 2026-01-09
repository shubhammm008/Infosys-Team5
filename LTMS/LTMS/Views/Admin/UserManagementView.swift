//
//  UserManagementView.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import SwiftUI
import Combine
import Supabase

@MainActor
class UserManagementViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var selectedRole: UserRole?
    
    private let mockDataService = MockDataService.shared
    
    var filteredUsers: [User] {
        var filtered = users
        
        if let role = selectedRole {
            filtered = filtered.filter { $0.role == role }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.fullName.localizedCaseInsensitiveContains(searchText) ||
                $0.email.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    func fetchUsers() async {
        isLoading = true
        defer { isLoading = false }
        
        // Check if we're in test mode by checking if any user has @test.com email
        // Or if MockDataService has users
        let mockUsers = mockDataService.getUsers()
        
        if !mockUsers.isEmpty {
            // Use mock data
            users = mockUsers
            return
        }
        
        // Try to fetch from database
        do {
            users = try await SupabaseService.shared.fetchAll(from: FirebaseConstants.users)
        } catch {
            print("Error fetching users: \(error)")
            // Fallback to mock data if fetch fails
            users = mockDataService.getUsers()
        }
    }
    
    func deleteUser(id: String) async throws {
        // Check if this is a mock user
        if users.first(where: { $0.id == id })?.email.hasSuffix("@test.com") == true ||
           users.first(where: { $0.id == id })?.email.hasSuffix("@ltms.test") == true {
            mockDataService.deleteUser(id: id)
            users.removeAll { $0.id == id }
        } else {
            try await SupabaseService.shared.delete(id: id, from: FirebaseConstants.users)
            users.removeAll { $0.id == id }
        }
    }
    
    func toggleUserStatus(user: User) async throws {
        var updatedUser = user
        updatedUser.isActive.toggle()
        
        // Check if this is a mock user
        if user.email.hasSuffix("@test.com") || user.email.hasSuffix("@ltms.test") {
            mockDataService.updateUser(updatedUser)
        } else {
            try await SupabaseService.shared.update(updatedUser, id: updatedUser.id, in: FirebaseConstants.users)
        }
        
        if let index = users.firstIndex(where: { $0.id == user.id }) {
            users[index] = updatedUser
        }
    }
    
    func changeUserRole(user: User, newRole: UserRole) async throws {
        var updatedUser = user
        updatedUser.role = newRole
        updatedUser.updatedAt = Date()
        
        // Check if this is a mock user
        if user.email.hasSuffix("@test.com") || user.email.hasSuffix("@ltms.test") {
            mockDataService.updateUser(updatedUser)
        } else {
            try await SupabaseService.shared.update(updatedUser, id: updatedUser.id, in: FirebaseConstants.users)
        }
        
        if let index = users.firstIndex(where: { $0.id == user.id }) {
            users[index] = updatedUser
        }
    }
}

struct UserManagementView: View {
    @StateObject private var viewModel = UserManagementViewModel()
    @State private var showCreateUser = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search and Filter
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search users...", text: $viewModel.searchText)
                    }
                    .padding()
                    .background(Color.ltmsCardBackground)
                    .cornerRadius(12)
                    
                    // Role Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            FilterChip(title: "All", isSelected: viewModel.selectedRole == nil) {
                                viewModel.selectedRole = nil
                            }
                            
                            ForEach(UserRole.allCases, id: \.self) { role in
                                FilterChip(title: role.displayName, isSelected: viewModel.selectedRole == role) {
                                    viewModel.selectedRole = role
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
                .background(Color.ltmsBackground)
                
                // User List
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if viewModel.filteredUsers.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No users found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.filteredUsers) { user in
                            UserRow(user: user, viewModel: viewModel)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color.ltmsBackground)
            .navigationTitle("User Management")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateUser = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showCreateUser) {
                CreateUserView()
            }
            .task {
                await viewModel.fetchUsers()
            }
        }
    }
}

struct UserRow: View {
    let user: User
    @ObservedObject var viewModel: UserManagementViewModel
    @State private var showDeleteAlert = false
    @State private var showRoleChangeSheet = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(roleColor.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(user.firstName.prefix(1) + user.lastName.prefix(1))
                        .font(.headline)
                        .foregroundColor(roleColor)
                )
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                Text(user.fullName)
                    .font(.headline)
                
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    Text(user.role.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(roleColor.opacity(0.2))
                        .foregroundColor(roleColor)
                        .cornerRadius(6)
                    
                    if !user.isActive {
                        Text("Inactive")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(6)
                    }
                }
            }
            
            Spacer()
            
            // Actions Menu
            Menu {
                // Change Role
                Menu {
                    ForEach(UserRole.allCases, id: \.self) { role in
                        Button {
                            Task {
                                try? await viewModel.changeUserRole(user: user, newRole: role)
                            }
                        } label: {
                            HStack {
                                Text(role.displayName)
                                if user.role == role {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Label("Change Role", systemImage: "person.badge.key")
                }
                
                Divider()
                
                // Activate/Deactivate
                Button {
                    Task {
                        try? await viewModel.toggleUserStatus(user: user)
                    }
                } label: {
                    Label(user.isActive ? "Deactivate" : "Activate", systemImage: user.isActive ? "pause.circle" : "play.circle")
                }
                
                Divider()
                
                // Delete
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .alert("Delete User", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    try? await viewModel.deleteUser(id: user.id)
                }
            }
        } message: {
            Text("Are you sure you want to delete \(user.fullName)?")
        }
    }
    
    private var roleColor: Color {
        switch user.role {
        case .admin: return .blue
        case .educator: return .purple
        case .learner: return .green
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.ltmsPrimary : Color.ltmsCardBackground)
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

#Preview {
    UserManagementView()
}
