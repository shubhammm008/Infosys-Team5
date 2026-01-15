//
//  AdminDashboardView.swift
//  LTMS
//

import SwiftUI
import Combine

extension Color {

    // MARK: - Backgrounds
    // Soft academic paper tone
    static let dashboardBg = LinearGradient(
        colors: [
            Color(hex: "#FBF6F3"), // warm off-white
            Color(hex: "#F2E9E6")  // subtle cream
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - Card Surfaces
    static let dashboardCard = Color(hex: "#FFFFFF")      // reading surface
    static let dashboardCardAlt = Color(hex: "#F7EFEA")   // grouped sections

    // MARK: - Text
    static let dashboardTextPrimary = Color(hex: "#2B1E1E")   // deep wine-black
    static let dashboardTextSecondary = Color(hex: "#6B4A4A") // muted maroon

    // MARK: - Brand Accents (from design you shared)
    static let accentPrimary = Color(hex: "#7A2E3A")   // main maroon
    static let accentSecondary = Color(hex: "#9C4A55") // lighter wine

    // MARK: - Status
    static let accentSuccess = Color(hex: "#4F8A6F")   // calm green
    static let accentWarning = Color(hex: "#C08A5A")   // warm alert
    static let accentHighlight = Color(hex: "#F2E0D8") // subtle emphasis
}

// MARK: - Hex Support
extension Color {
    init(hex: String) {
        let hex = hex.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)

        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}




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
                                        tint: .orange
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
                    .foregroundColor(.white.opacity(0.9))

                Text(value)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.75))
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


// MARK: - Profile

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
                            .foregroundColor(.accentPrimary)

                        VStack(alignment: .leading) {
                            Text(authService.currentUser?.fullName ?? "")
                            Text(authService.currentUser?.email ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section {
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
            }
        }
    }
}

#Preview {
    AdminDashboardView()
}
