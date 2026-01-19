//
//  EducatorDashboardView.swift
//  LTMS
//

import SwiftUI

// MARK: - ROOT
// MARK: - ROOT
struct EducatorDashboardView: View {
    @State private var selectedTab = 0
    
    init() {
        // Customize TabBar appearance for dark theme
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.dashboardCard)
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            EducatorHomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            EducatorAnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.fill")
                }
                .tag(1)
            
            EducatorProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
                .tag(2)
        }
        .tint(.accentBlue)
    }
}

// MARK: - HOME
struct EducatorHomeView: View {
    @StateObject private var authService = SupabaseAuthService.shared
    @State private var courses: [Course] = []
    @State private var isLoading = false
    @State private var showCreateCourse = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.dashboardBg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 28) {
                        header
                        statsSection
                        coursesSection
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showCreateCourse) {
                EducatorCreateCourseView {
                    // Refresh courses after creation
                    Task {
                        await loadCourses()
                    }
                }
            }
            .task {
                await loadCourses()
            }
            .onAppear {
                Task {
                    await loadCourses()
                }
            }
        }
    }
    
    // MARK: Header
    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Good Morning,")
                    .font(.subheadline)
                    .foregroundColor(.dashboardTextSecondary)
                
                Text(authService.currentUser?.fullName ?? "Educator")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.dashboardTextPrimary)
            }
            
            Spacer()
            
            // Create Course Button
            Button {
                showCreateCourse = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        LinearGradient(
                            colors: [.accentBlue, .accentPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: .accentBlue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
    }
    
    // MARK: Stats
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ongoing Stats")
                .font(.headline)
                .foregroundColor(.dashboardTextPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                
                statCard(
                    title: "Courses",
                    value: "\(courses.count)",
                    icon: "book.fill",
                    highlight: true
                )
                
                statCard(
                    title: "Total Hours",
                    value: "\(courses.reduce(0) { $0 + $1.durationHours })",
                    icon: "clock.fill"
                )
            }
        }
    }
    
    private func statCard(
        title: String,
        value: String,
        icon: String,
        highlight: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.dashboardTextPrimary.opacity(0.85))
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.dashboardTextPrimary)
            
            Text(title.uppercased())
                .font(.caption)
                .foregroundColor(.dashboardTextSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(
            highlight ?
            LinearGradient(
                colors: [Color.accentBlue, Color.accentBlue.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ) :
            LinearGradient(
                colors: [
                    Color.dashboardCard,
                    Color.dashboardCard.opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(22)
    }
    
    // MARK: Courses
    private var coursesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("My Courses")
                .font(.headline)
                .foregroundColor(.dashboardTextPrimary)
            
            if isLoading {
                ProgressView()
                    .tint(.accentBlue)
                    .padding(.top, 40)
            } else if courses.isEmpty {
                emptyState
            } else {
                ForEach(courses) { course in
                    NavigationLink {
                        CourseBuilderView(course: course)
                    } label: {
                        EducatorCourseCard(course: course)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 48))
                .foregroundColor(.dashboardTextSecondary)
            
            Text("No Courses Yet")
                .font(.headline)
                .foregroundColor(.dashboardTextPrimary)
            
            Text("Tap the + button above to create your first course.")
                .font(.subheadline)
                .foregroundColor(.dashboardTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: Data
    private func loadCourses() async {
        guard let userId = authService.currentUser?.id else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            let all: [Course] = try await SupabaseService.shared.fetchAll(from: SupabaseConstants.courses)
            // Show courses that are either assigned to or created by this educator
            courses = all.filter { $0.assignedEducatorId == userId || $0.createdById == userId }
        } catch {
            courses = []
        }
    }
}

// MARK: - COURSE CARD
struct EducatorCourseCard: View {
    let course: Course
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(course.title)
                .font(.headline)
                .foregroundColor(.dashboardTextPrimary)
            
            Text(course.courseDescription)
                .font(.subheadline)
                .foregroundColor(.dashboardTextSecondary)
                .lineLimit(2)
            
            HStack {
                Label("\(course.durationHours)h", systemImage: "clock")
                
                Spacer()
                
                // Approval Status Badge
                if course.isPublished {
                    Text("Published")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(8)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.badge.exclamationmark")
                            .font(.caption2)
                        Text("Pending Approval")
                            .font(.caption)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(8)
                }
            }
            .font(.caption)
            .foregroundColor(.dashboardTextSecondary)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [
                    Color.dashboardCard,
                    Color.dashboardCard.opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
    }
}

// MARK: - PROFILE
struct EducatorProfileView: View {
    @StateObject private var authService = SupabaseAuthService.shared
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showLogout = false
    @State private var showEditProfile = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.dashboardBg.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Header
                    HStack {
                        Text("Profile")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.dashboardTextPrimary)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Profile Header with Edit Button
                            VStack(spacing: 16) {
                                ZStack(alignment: .topTrailing) {
                                    VStack(spacing: 16) {
                                        // Profile Picture
                                        ZStack {
                                            Circle()
                                                .fill(
                                                    LinearGradient(
                                                        colors: [.accentBlue, .accentPurple],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .frame(width: 100, height: 100)
                                            
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 50))
                                                .foregroundColor(.white)
                                        }
                                        
                                        VStack(spacing: 4) {
                                            Text(authService.currentUser?.fullName ?? "Educator")
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.dashboardTextPrimary)
                                            
                                            Text(authService.currentUser?.email ?? "")
                                                .font(.subheadline)
                                                .foregroundColor(.dashboardTextSecondary)
                                            
                                            // Role Badge
                                            HStack(spacing: 4) {
                                                Image(systemName: "person.badge.key.fill")
                                                    .font(.caption2)
                                                Text("Educator")
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                LinearGradient(
                                                    colors: [.accentBlue.opacity(0.2), .accentPurple.opacity(0.2)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                            .foregroundColor(.accentBlue)
                                            .cornerRadius(12)
                                        }
                                    }
                                    
                                    // Edit Button
                                    Button {
                                        showEditProfile = true
                                    } label: {
                                        Image(systemName: "pencil.circle.fill")
                                            .font(.title2)
                                            .foregroundColor(.accentBlue)
                                            .background(
                                                Circle()
                                                    .fill(Color.dashboardCard)
                                                    .frame(width: 36, height: 36)
                                            )
                                    }
                                    .padding(8)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                            .background(Color.dashboardCard)
                            .cornerRadius(20)
                            
                            // Profile Information
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Profile Information")
                                    .font(.headline)
                                    .foregroundColor(.dashboardTextPrimary)
                                    .padding(.horizontal)
                                
                                VStack(spacing: 1) {
                                    EducatorInfoRow(
                                        icon: "person.fill",
                                        label: "Full Name",
                                        value: authService.currentUser?.fullName ?? "Not set"
                                    )
                                    
                                    Divider()
                                        .padding(.leading, 52)
                                    
                                    EducatorInfoRow(
                                        icon: "envelope.fill",
                                        label: "Email",
                                        value: authService.currentUser?.email ?? "Not set"
                                    )
                                    
                                    Divider()
                                        .padding(.leading, 52)
                                    
                                    EducatorInfoRow(
                                        icon: "calendar.badge.clock",
                                        label: "Member Since",
                                        value: authService.currentUser?.createdAt.formatted(date: .abbreviated, time: .omitted) ?? "Unknown"
                                    )
                                }
                                .background(Color.dashboardCard)
                                .cornerRadius(16)
                                .padding(.horizontal)
                            }
                            
                            // Appearance Section
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Appearance")
                                    .font(.headline)
                                    .foregroundColor(.dashboardTextPrimary)
                                    .padding(.horizontal)
                                
                                VStack(spacing: 1) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "paintbrush.fill")
                                            .foregroundColor(.dashboardTextSecondary)
                                            .frame(width: 24)
                                        Text("Theme")
                                            .foregroundColor(.dashboardTextPrimary)
                                        Spacer()
                                        Picker("", selection: $themeManager.selectedTheme) {
                                            ForEach(AppTheme.allCases, id: \.self) { theme in
                                                Text(theme.displayName).tag(theme)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .tint(.accentBlue)
                                    }
                                    .padding()
                                    .background(Color.dashboardCard)
                                }
                                .cornerRadius(16)
                                .padding(.horizontal)
                            }
                            
                            // Actions Section
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Account")
                                    .font(.headline)
                                    .foregroundColor(.dashboardTextPrimary)
                                    .padding(.horizontal)
                                
                                VStack(spacing: 1) {
                                    Button(role: .destructive) {
                                        showLogout = true
                                    } label: {
                                        HStack {
                                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                                .foregroundColor(.red)
                                            Text("Sign Out")
                                                .foregroundColor(.dashboardTextPrimary)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundColor(.dashboardTextSecondary)
                                        }
                                        .padding()
                                        .background(Color.dashboardCard)
                                    }
                                }
                                .cornerRadius(16)
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("Sign Out", isPresented: $showLogout) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    Task {
                        try? await authService.signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
            }
        }
    }
}

// MARK: - Supporting Views for Educator Profile

struct EducatorStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.dashboardTextPrimary)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.dashboardTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.dashboardCard)
        .cornerRadius(16)
    }
}

struct EducatorInfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.accentBlue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.dashboardTextSecondary)
                
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.dashboardTextPrimary)
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    EducatorDashboardView()
}
