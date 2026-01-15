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
            
            EducatorProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
                .tag(1)
        }
        .tint(.accentBlue)
    }
}

// MARK: - HOME
struct EducatorHomeView: View {
    @StateObject private var authService = SupabaseAuthService.shared
    @State private var courses: [Course] = []
    @State private var isLoading = false
    
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
            .task {
                await loadCourses()
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
            
            NavigationLink {
                CreateCourseView()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        LinearGradient(
                            colors: [Color.accentBlue, Color.accentPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(14)
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
            
            Text("No Courses Assigned")
                .font(.headline)
                .foregroundColor(.dashboardTextPrimary)
            
            Text("Tap + to create a course.")
                .font(.subheadline)
                .foregroundColor(.dashboardTextSecondary)
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
            courses = all.filter { $0.assignedEducatorId == userId }
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
                
                Text(course.level.displayName)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.accentBlue.opacity(0.2))
                    .foregroundColor(.accentBlue)
                    .cornerRadius(8)
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
    @State private var showLogout = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.dashboardBg.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Header to match Home
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
                            // User Info Profile Card
                            VStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.accentBlue.opacity(0.1))
                                        .frame(width: 100, height: 100)
                                    
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 80))
                                        .foregroundColor(.accentBlue)
                                }
                                
                                VStack(spacing: 4) {
                                    Text(authService.currentUser?.fullName ?? "Educator")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.dashboardTextPrimary)
                                    
                                    Text(authService.currentUser?.email ?? "")
                                        .font(.subheadline)
                                        .foregroundColor(.dashboardTextSecondary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                            .background(Color.dashboardCard)
                            .cornerRadius(24)
                            
                            // Actions Section
                            VStack(spacing: 1) {
                                Button(role: .destructive) {
                                    showLogout = true
                                } label: {
                                    HStack {
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                            .foregroundColor(.red)
                                        Text("Sign Out")
                                            .foregroundColor(.red)
                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color.dashboardCard)
                                }
                            }
                            .cornerRadius(16)
                            .padding(.top, 8)
                        }
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("Sign Out", isPresented: $showLogout) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    Task { try? await authService.signOut() }
                }
            }
        }
    }
}

#Preview {
    EducatorDashboardView()
}
