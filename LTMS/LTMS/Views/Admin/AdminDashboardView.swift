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
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            AnalyticsDashboardView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.fill")
                }
                .tag(1)
            
            UserManagementView(preselectedRole: $selectedUserRole)
                .tabItem {
                    Label("Users", systemImage: "person.3.fill")
                }
                .tag(2)
            
            CourseManagementView()
                .tabItem {
                    Label("Courses", systemImage: "book.fill")
                }
                .tag(3)
            
            EnrollmentManagementView()
                .tabItem {
                    Label("Enrollments", systemImage: "person.badge.plus")
                }
                .tag(4)
            
            ReportsView()
                .tabItem {
                    Label("Reports", systemImage: "doc.text.fill")
                }
                .tag(5)
            
            AdminProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
                .tag(6)
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
    @Binding var selectedTab: Int
    @Binding var selectedUserRole: UserRole?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Welcome back,")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(authService.currentUser?.firstName ?? "Admin")
                                .font(.title)
                                .fontWeight(.bold)
                        }
                        Spacer()
                        
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.ltmsPrimary)
                    }
                    .padding()
                    .background(Color.ltmsCardBackground)
                    .cornerRadius(16)
                    
                    // Quick Stats
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatCard(
                            title: "Total Users",
                            value: "\(viewModel.totalUsers)",
                            icon: "person.3.fill",
                            color: .blue
                        ) {
                            selectedUserRole = nil
                            selectedTab = 2
                        }
                        
                        StatCard(
                            title: "Total Courses",
                            value: "\(viewModel.totalCourses)",
                            icon: "book.fill",
                            color: .purple
                        ) {
                            selectedTab = 3
                        }
                        
                        StatCard(
                            title: "Educators",
                            value: "\(viewModel.totalEducators)",
                            icon: "person.badge.key.fill",
                            color: .orange
                        ) {
                            selectedUserRole = .educator
                            selectedTab = 2
                        }
                        
                        StatCard(
                            title: "Learners",
                            value: "\(viewModel.totalLearners)",
                            icon: "graduationcap.fill",
                            color: .green
                        ) {
                            selectedUserRole = .learner
                            selectedTab = 2
                        }
                    }
                    
                    // Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            QuickActionButton(
                                title: "Create Educator Account",
                                icon: "person.badge.plus",
                                color: .blue
                            ) {
                                showCreateUser = true
                            }
                            
                            QuickActionButton(
                                title: "Create New Course",
                                icon: "plus.circle.fill",
                                color: .purple
                            ) {
                                showCreateCourse = true
                            }
                            
                            QuickActionButton(
                                title: "View Analytics Dashboard",
                                icon: "chart.bar.fill",
                                color: .green
                            ) {
                                selectedTab = 1
                            }
                            
                            QuickActionButton(
                                title: "Manage Enrollments",
                                icon: "person.badge.plus",
                                color: .orange
                            ) {
                                selectedTab = 4
                            }
                            
                            QuickActionButton(
                                title: "Generate Reports",
                                icon: "doc.text.fill",
                                color: .red
                            ) {
                                selectedTab = 5
                            }
                        }
                    }
                }
                .padding()
            }
            .refreshable {
                await viewModel.loadStats()
            }
            .background(Color.ltmsBackground)
            .navigationTitle("Dashboard")
            .sheet(isPresented: $showCreateUser) {
                CreateUserView()
            }
            .sheet(isPresented: $showCreateCourse) {
                CreateCourseView()
            }
            .task {
                await viewModel.loadStats()
            }
        }
    }
}

// MARK: - Supporting Views

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
