//
//  AdminDashboardView.swift
//  LTMS
//

import SwiftUI
import Combine






// MARK: - Root Dashboard

struct AdminDashboardView: View {
    @State private var selectedTab = 0
    @State private var selectedUserRole: UserRole?

    var body: some View {
        TabView(selection: $selectedTab) {

            AdminHomeView(
                selectedTab: $selectedTab,
                selectedUserRole: $selectedUserRole
            )
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
        .tint(.accentPrimary)   // ✅ education green
        .preferredColorScheme(.dark)
    }
}


// MARK: - ViewModel

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
            let users: [User] = try await SupabaseService.shared.fetchAll(from: SupabaseConstants.users)
            totalUsers = users.count

            let educators: [User] = try await SupabaseService.shared.fetchUsersByRole(.educator, in: AppConstants.defaultOrganizationId)
            totalEducators = educators.count

            let learners: [User] = try await SupabaseService.shared.fetchUsersByRole(.learner, in: AppConstants.defaultOrganizationId)
            totalLearners = learners.count

            let courses: [Course] = try await SupabaseService.shared.fetchAll(from: SupabaseConstants.courses)
            totalCourses = courses.count
        } catch {
            print("❌ Error loading stats: \(error)")
        }
    }
}

// MARK: - Admin Home View

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

    var body: some View { NavigationStack { ScrollView { VStack(spacing: 24) { // MARK: - Admin Context Header
        VStack(alignment: .leading, spacing: 4){
            Text("Welcome Back")
                .font(.default)
                .foregroundColor(.dashboardTextSecondary)
            HStack {
                Text("Admin")
                    .font(.title.bold())
                    .foregroundColor(.dashboardTextPrimary)
                Spacer()
                Button {
                    showAdminProfile = true
                }
                label: {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 42))
                        .foregroundColor(.dashboardTextPrimary)
                }
            }
        }
        .sheet(isPresented: $showAdminProfile) {
            AdminProfileView()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        

                    // MARK: Needs Attention
                    if pendingPublishCount > 0 || draftCoursesCount > 0 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Needs Attention")
                                .font(.headline)
                                .foregroundColor(.dashboardTextPrimary)

                            VStack(spacing: 10) {
                                if pendingPublishCount > 0 {
                                    AttentionRow(
                                        title: "Courses awaiting approval",
                                        subtitle: "Publish requests from educators",
                                        count: pendingPublishCount,
                                        icon: "clock.fill",
                                        tint: .accentWarning
                                    ) {
                                        showCourseManagement = true
                                    }
                                }

                                if draftCoursesCount > 0 {
                                    AttentionRow(
                                        title: "Draft courses",
                                        subtitle: "Created but not published",
                                        count: draftCoursesCount,
                                        icon: "doc.text.fill",
                                        tint: .accentSecondary
                                    ) {
                                        showCourseManagement = true
                                    }
                                }
                            }
                        }
                    }

                    // MARK: System Overview
                    VStack(alignment: .leading, spacing: 12) {
                        Text("System Overview")
                            .font(.headline)
                            .foregroundColor(.dashboardTextPrimary)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {

                            StatCard(
                                title: "Users",
                                value: "\(viewModel.totalUsers)",
                                icon: "person.3.fill",
                                gradient: [.accentPrimary, .accentSecondary]
                            ) {
                                selectedUserRole = nil
                                showUserManagement = true
                            }

                            StatCard(
                                title: "Courses",
                                value: "\(viewModel.totalCourses)",
                                icon: "book.fill",
                                gradient: [.accentPrimary, .accentSecondary]
                            ) {
                                showCourseManagement = true
                            }
                        }
                    }

                    // MARK: Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.headline)
                            .foregroundColor(.dashboardTextPrimary)

                        VStack(spacing: 12) {
                            PrimaryActionButton(title: "Create Course", icon: "plus.circle.fill") {
                                showCreateCourse = true
                            }

                            PrimaryActionButton(title: "Add Educator", icon: "person.badge.plus") {
                                showCreateUser = true
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color.dashboardBg)
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.loadStats() }
            .sheet(isPresented: $showCreateUser) { CreateUserView() }
            .sheet(isPresented: $showCreateCourse) { CreateCourseView() }
            .sheet(isPresented: $showCourseManagement) { CourseManagementView() }
            .sheet(isPresented: $showUserManagement) { UserManagementView() }
            .sheet(isPresented: $showEnrollmentManagement) { EnrollmentManagementView() }
            .sheet(isPresented: $showAdminProfile) { AdminProfileView() }
        }
    }
}

// MARK: - Components

struct AttentionRow: View {
    let title: String
    let subtitle: String
    let count: Int
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(tint)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundColor(.dashboardTextPrimary)
                        .font(.subheadline)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.dashboardTextSecondary)
                }

                Spacer()

                Text("\(count)")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(tint.opacity(0.2))
                    .foregroundColor(tint)
                    .cornerRadius(10)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.dashboardTextSecondary)
            }
            .padding()
            .background(Color.dashboardCard)
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
}



struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let gradient: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.textOnAccent.opacity(0.9))

                Text(value)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.textOnAccent)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.textOnAccent.opacity(0.75))
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: gradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(18)
            .overlay(
                Image(systemName: "chevron.right")
                    .foregroundColor(.textOnAccent.opacity(0.5))
                    .padding()
                , alignment: .topTrailing
            )
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
                Text(title).fontWeight(.semibold)
                Spacer()
                Image(systemName: "chevron.right")
            }
            .foregroundColor(.accentPrimary)
            .padding()
            .background(Color.dashboardCardAlt)
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }
}

struct AdminProfileView: View {
    @StateObject private var authService = SupabaseAuthService.shared
    @State private var showLogoutAlert = false
    @Environment(\.dismiss) var dismiss

    
    var body: some View {
        NavigationStack {
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
                                .background(Color.accentPrimary.opacity(0.1))
                                .foregroundColor(.accentPrimary)
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
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
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

//struct PrivacyPolicyView: View {
//    var body: some View {
//        List {
//            Section {
//                VStack(alignment: .leading, spacing: 8) {
//                    Text("Privacy Policy")
//                        .font(.title)
//                        .fontWeight(.bold)
//                    
//                    Text("Last updated: January 15, 2026")
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                }
//                .padding(.vertical, 8)
//            }
//            
//            Section("1. Introduction") {
//                Text("Welcome to the Learning & Training Management System (LTMS). We value your privacy and are committed to protecting your personal data.")
//                    .font(.callout)
//                    .foregroundColor(.secondary)
//            }
//            
//            Section("2. Data Collection") {
//                Text("We collect information you provide directly to us, such as when you create an account, enroll in a course, or communicate with our support team.")
//                    .font(.callout)
//                    .foregroundColor(.secondary)
//            }
//            
//            Section("3. Use of Information") {
//                Text("We use the information we collect to provide, maintain, and improve our services, including to process transactions, send you technical notices, and respond to your comments.")
//                    .font(.callout)
//                    .foregroundColor(.secondary)
//            }
//            
//            Section("4. Data Security") {
//                Text("We implement appropriate technical and organizational measures to protect specific data against accidental or unlawful destruction, loss, alteration, or unauthorized disclosure.")
//                    .font(.callout)
//                    .foregroundColor(.secondary)
//            }
//            
//            Section("5. Contact Us") {
//                Text("If you have any questions about this Privacy Policy, please contact us at privacy@ltms.com.")
//                    .font(.callout)
//                    .foregroundColor(.secondary)
//            }
//        }
//        .navigationTitle("Privacy Policy")
//        .navigationBarTitleDisplayMode(.inline)
//    }
//}
//
//struct TermsOfServiceView: View {
//    var body: some View {
//        List {
//            Section {
//                VStack(alignment: .leading, spacing: 8) {
//                    Text("Terms of Service")
//                        .font(.title)
//                        .fontWeight(.bold)
//                    
//                    Text("Last updated: January 15, 2026")
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                }
//                .padding(.vertical, 8)
//            }
//            
//            Section("1. Acceptance of Terms") {
//                Text("By accessing or using our service, you agree to be bound by these Terms of Service and all applicable laws and regulations.")
//                    .font(.callout)
//                    .foregroundColor(.secondary)
//            }
//            
//            Section("2. User Accounts") {
//                Text("You are responsible for safeguarding the password that you use to access the service and for any activities or actions under your password.")
//                    .font(.callout)
//                    .foregroundColor(.secondary)
//            }
//            
//            Section("3. Content Guidelines") {
//                Text("Users may not post content that is illegal, offensive, or infringes on the rights of others. We reserve the right to remove any content that violates these terms.")
//                    .font(.callout)
//                    .foregroundColor(.secondary)
//            }
//            
//            Section("4. Termination") {
//                Text("We may terminate or suspend your account immediately, without prior notice or liability, for any reason whatsoever, including without limitation if you breach the Terms.")
//                    .font(.callout)
//                    .foregroundColor(.secondary)
//            }
//            
//            Section("5. Disclaimer") {
//                Text("The service is provided on an 'AS IS' and 'AS AVAILABLE' basis. We make no warranties, expressed or implied, regarding the operation of the service.")
//                    .font(.callout)
//                    .foregroundColor(.secondary)
//            }
//        }
//        .navigationTitle("Terms of Service")
//        .navigationBarTitleDisplayMode(.inline)
//    }
//}
//

#Preview {
    AdminDashboardView()
}

