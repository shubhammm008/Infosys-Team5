//
//  AdminDashboardView.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import SwiftUI
import Combine

struct AdminDashboardView: View {
    @StateObject private var authService = SupabaseAuthService.shared
    @State private var selectedTab = 0
    
    @State private var selectedUserRole: UserRole?
    
    var body: some View {
        TabView(selection: $selectedTab) {
            AdminHomeView(selectedTab: $selectedTab, selectedUserRole: $selectedUserRole)
                .tabItem {
                    Label("Dashboard", systemImage: "rectangle.grid.2x2.fill")
                }
                .tag(0)

            
            AnalyticsDashboardView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.fill")
                }
                .tag(1)
            
            
            ReportsView()
                .tabItem {
                    Label("Reports", systemImage: "doc.text.fill")
                }
                .tag(2)

        }
        .tint(.ltmsPrimary)
    }
}

// MARK: - Admin Home View

@MainActor
class AdminHomeViewModel: ObservableObject {
    @Published var totalUsers = 0
    @Published var totalEducators = 0
    @Published var totalLearners = 0
    @Published var totalCourses = 0
    @Published var isLoading = false
    
    func loadStats() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Fetch all users from Supabase
            let users: [User] = try await SupabaseService.shared.fetchAll(from: SupabaseConstants.users)
            totalUsers = users.count
            
            // Use server-side filtering for better performance
            let educators: [User] = try await SupabaseService.shared.fetchUsersByRole(.educator, in: AppConstants.defaultOrganizationId)
            totalEducators = educators.count
            
            let learners: [User] = try await SupabaseService.shared.fetchUsersByRole(.learner, in: AppConstants.defaultOrganizationId)
            totalLearners = learners.count
            
            // Fetch all courses from Supabase
            let courses: [Course] = try await SupabaseService.shared.fetchAll(from: SupabaseConstants.courses)
            totalCourses = courses.count
            
            print("✅ Loaded stats: \(totalUsers) users (\(totalEducators) educators, \(totalLearners) learners), \(totalCourses) courses")
        } catch {
            print("❌ Error loading stats: \(error)")
        }
    }
}

struct AdminHomeView: View {
    @StateObject private var authService = SupabaseAuthService.shared
    @StateObject private var viewModel = AdminHomeViewModel()
    
    @State private var showCreateUser = false
    @State private var showCreateCourse = false
    @State private var showAdminProfile = false
    @State private var showUserManagement = false
    @State private var showCourseManagement = false
    @State private var showEnrollmentManagement = false
    @State private var pendingPublishCount = 2
    @State private var draftCoursesCount = 1



    
    @Binding var selectedTab: Int
    @Binding var selectedUserRole: UserRole?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    
                    // MARK: - Admin Context Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Welcome Back")
                            .font(.default)
                            .foregroundColor(.secondary)

                        HStack {
                            Text("Admin")
                                .font(.title.bold())


                            Spacer()

                            Button {
                                showAdminProfile = true
                            } label: {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 42))
                                    .foregroundColor(.ltmsPrimary)
                            }

                        }

                    }
                    .sheet(isPresented: $showAdminProfile) {
                        AdminProfileView()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    
                    // MARK: - Needs Attention
                    if pendingPublishCount > 0 || draftCoursesCount > 0 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Needs Attention")
                                .font(.headline)

                            VStack(spacing: 8) {

                                if pendingPublishCount > 0 {
                                    AttentionRow(
                                        title: "Courses awaiting approval",
                                        subtitle: "Publish requests from educators",
                                        count: pendingPublishCount,
                                        icon: "clock.fill"
                                    ) {
                                        showCourseManagement = true
                                    }
                                }

                                if draftCoursesCount > 0 {
                                    AttentionRow(
                                        title: "Draft courses",
                                        subtitle: "Created but not published",
                                        count: draftCoursesCount,
                                        icon: "doc.text.fill"
                                    ) {
                                        showCourseManagement = true
                                    }
                                }
                            }
                        }
                    }

                    
                    
                    // MARK: - Attention Required
                    VStack(alignment: .leading, spacing: 12) {
                        Text("System Overview")
                            .font(.headline)
                        
                        LazyVGrid(
                            columns: [GridItem(.flexible()), GridItem(.flexible())],
                            spacing: 16
                        ) {
                            AttentionCard(
                                title: "Users",
                                value: viewModel.totalUsers,
                                icon: "person.3.fill",
                                color: .blue
                            ) {
                                selectedUserRole = nil
                                showUserManagement = true
                            }
                            
                            AttentionCard(
                                title: "Courses",
                                value: viewModel.totalCourses,
                                icon: "book.fill",
                                color: .purple
                            ) {
                                showCourseManagement = true
                            }
                        }
                    }
                    .sheet(isPresented: $showCourseManagement) {
                        CourseManagementView()
                    }
                    .sheet(isPresented: $showUserManagement) {
                        UserManagementView()
                    }
                    
                    // MARK: - Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.headline)
                        
                        VStack(spacing: 12) {
                            PrimaryActionButton(
                                title: "Create Course",
                                icon: "plus.circle.fill"
                            ) {
                                showCreateCourse = true
                            }
                            
                            PrimaryActionButton(
                                title: "Add Educator",
                                icon: "person.badge.plus"
                            ) {
                                showCreateUser = true
                            }
                            
                            PrimaryActionButton(title: "Manage Enrollments", icon: "person.badge.plus")
                            {
                                showEnrollmentManagement = true
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color.ltmsBackground)
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await viewModel.loadStats()
            }
            .sheet(isPresented: $showCreateUser) {
                CreateUserView()
            }
            .sheet(isPresented: $showCreateCourse) {
                CreateCourseView()
            }
            .sheet(isPresented: $showEnrollmentManagement) {
                EnrollmentManagementView()
            }
            .task {
                await viewModel.loadStats()
            }
        }
    }
}


// MARK: - Supporting Views

struct AttentionRow: View {
    let title: String
    let subtitle: String
    let count: Int
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(10)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}


struct AttentionCard: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                    Spacer()
//                    Image(systemName: "chevron.right")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
                }
                
                Text("\(value)")
                    .font(.system(size: 26, weight: .bold))
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.ltmsCardBackground)
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
}

struct PrimaryActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                
                Text(title)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.caption)
            }
            .padding()
            .background(Color.white)
            .foregroundColor(.ltmsPrimary)
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
}



struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var action: (() -> Void)? = nil
    
    var body: some View {
        Button(action: {
            action?()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    Spacer()
                    if action != nil {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.ltmsCardBackground)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(title)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.ltmsCardBackground)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct AdminProfileView: View {
    @StateObject private var authService = SupabaseAuthService.shared
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.ltmsPrimary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authService.currentUser?.fullName ?? "")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text(authService.currentUser?.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(authService.currentUser?.role.displayName ?? "")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.ltmsPrimary.opacity(0.2))
                                .foregroundColor(.ltmsPrimary)
                                .cornerRadius(6)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Account") {
                    Button(role: .destructive) {
                        showLogoutAlert = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Profile")
            .alert("Sign Out", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    Task { try? await authService.signOut() }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}

#Preview {
    AdminDashboardView()
}
