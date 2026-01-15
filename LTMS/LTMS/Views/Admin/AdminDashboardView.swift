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
        List {
            // Profile Header
            Section {
                HStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.gray)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(authService.currentUser?.fullName ?? "Admin User")
                            .font(.headline)
                        Text(authService.currentUser?.email ?? "admin@example.com")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(authService.currentUser?.role.displayName ?? "Administrator")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                    }
                }
                .padding(.vertical, 4)
            }
            

            
            // Support & About
            Section("Support") {
                NavigationLink {
                    HelpCenterView()
                } label: {
                    Label("Help & Support", systemImage: "questionmark.circle")
                }
                
                NavigationLink {
                    PrivacyPolicyView()
                } label: {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }
                
                NavigationLink {
                    TermsOfServiceView()
                } label: {
                    Label("Terms of Service", systemImage: "doc.text")
                }
            }
            
            // Account Actions
            Section {
                Button(role: .destructive) {
                    showLogoutAlert = true
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            } footer: {
                HStack {
                    Spacer()
                    Text("Version 1.0.0")
                    Spacer()
                }
                .padding(.top)
            }
        }
        .navigationTitle("Profile")
        .listStyle(.insetGrouped)
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

#Preview {
    AdminDashboardView()
}

struct HelpCenterView: View {
    var body: some View {
        List {
            Section("Frequently Asked Questions") {
                DisclosureGroup("How do I create a user?") {
                    Text("Go to the Users tab and click on the + button to add a new user. You can select their role (Admin, Educator, or Learner).")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                DisclosureGroup("How do I export reports?") {
                    Text("In the Analytics tab, look for the 'Export' button at the top right to download reports in PDF or CSV format.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                DisclosureGroup("Can I change my password?") {
                    Text("Currently, password resets are handled by the system administrator. Please contact IT support.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Contact Us") {
                Button {
                    // Action to copy email or open mail client
                } label: {
                    Label("support@ltms.com", systemImage: "envelope")
                }
                
                Button {
                    // Action to call support
                } label: {
                    Label("+1 (555) 123-4567", systemImage: "phone")
                }
            }
        }
        .navigationTitle("Help Center")
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Privacy Policy")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Last updated: January 15, 2026")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
            
            Section("1. Introduction") {
                Text("Welcome to the Learning & Training Management System (LTMS). We value your privacy and are committed to protecting your personal data.")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            
            Section("2. Data Collection") {
                Text("We collect information you provide directly to us, such as when you create an account, enroll in a course, or communicate with our support team.")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            
            Section("3. Use of Information") {
                Text("We use the information we collect to provide, maintain, and improve our services, including to process transactions, send you technical notices, and respond to your comments.")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            
            Section("4. Data Security") {
                Text("We implement appropriate technical and organizational measures to protect specific data against accidental or unlawful destruction, loss, alteration, or unauthorized disclosure.")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            
            Section("5. Contact Us") {
                Text("If you have any questions about this Privacy Policy, please contact us at privacy@ltms.com.")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Terms of Service")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Last updated: January 15, 2026")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
            
            Section("1. Acceptance of Terms") {
                Text("By accessing or using our service, you agree to be bound by these Terms of Service and all applicable laws and regulations.")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            
            Section("2. User Accounts") {
                Text("You are responsible for safeguarding the password that you use to access the service and for any activities or actions under your password.")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            
            Section("3. Content Guidelines") {
                Text("Users may not post content that is illegal, offensive, or infringes on the rights of others. We reserve the right to remove any content that violates these terms.")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            
            Section("4. Termination") {
                Text("We may terminate or suspend your account immediately, without prior notice or liability, for any reason whatsoever, including without limitation if you breach the Terms.")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            
            Section("5. Disclaimer") {
                Text("The service is provided on an 'AS IS' and 'AS AVAILABLE' basis. We make no warranties, expressed or implied, regarding the operation of the service.")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
    }
}
