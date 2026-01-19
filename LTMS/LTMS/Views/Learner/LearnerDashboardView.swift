//
//  LearnerDashboardView.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import SwiftUI
import Combine

struct LearnerDashboardView: View {
    @EnvironmentObject var authService: SupabaseAuthService
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
            CourseCatalogView()
                .tabItem {
                    Label("Discover", systemImage: "magnifyingglass")
                }
                .tag(0)
            
            MyCoursesView()
                .tabItem {
                    Label("My Courses", systemImage: "book.fill")
                }
                .tag(1)
            
            LearnerProgressView()
                .tabItem {
                    Label("Progress", systemImage: "chart.bar.fill")
                }
                .tag(2)
            
            LearnerProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
                .tag(3)
        }
        .tint(.accentBlue)
    }
}

// MARK: - Course Filter Enum

enum CourseFilter: String, CaseIterable {
    case enrolled = "Enrolled"
    case inProgress = "In Progress"
    case completed = "Completed"
    
    var displayName: String {
        rawValue
    }
}

// MARK: - Course Catalog View

@MainActor
class CourseCatalogViewModel: ObservableObject {
    @Published var courses: [Course] = []
    @Published var enrollments: [Enrollment] = []
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var selectedFilter: CourseFilter?
    
    var filteredCourses: [Course] {
        var filtered = courses.filter { $0.isPublished }
        
        if let filter = selectedFilter {
            filtered = filtered.filter { course in
                guard let enrollment = enrollments.first(where: { $0.courseId == course.id }) else {
                    return false // Not enrolled, exclude from filtered results
                }
                
                switch filter {
                case .enrolled:
                    // Show all enrolled courses that are NOT completed
                    // This includes courses with 0% progress (just enrolled) and in-progress courses
                    return enrollment.status == .active && enrollment.completionPercentage < 100
                case .inProgress:
                    // Show courses that are active and have started (progress > 0) but not completed
                    return enrollment.status == .active && enrollment.completionPercentage > 0 && enrollment.completionPercentage < 100
                case .completed:
                    // Show completed courses (either status is completed OR progress is 100%)
                    return enrollment.status == .completed || enrollment.completionPercentage >= 100
                }
            }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.courseDescription.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    func loadCourses(learnerId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            courses = try await CourseService.shared.fetchAllPublishedCourses()
            enrollments = try await ContentService.shared.fetchEnrollmentsByLearner(learnerId: learnerId)
        } catch {
            print("Error loading courses: \(error)")
        }
    }
}

struct CourseCatalogView: View {
    @StateObject private var viewModel = CourseCatalogViewModel()
    @StateObject private var authService = SupabaseAuthService.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search courses...", text: $viewModel.searchText)
                }
                .padding()
                .background(Color.dashboardCard)
                .cornerRadius(12)
                .padding()
                
                // Enrollment Status Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FilterChip(title: "All", isSelected: viewModel.selectedFilter == nil) {
                            viewModel.selectedFilter = nil
                        }
                        
                        ForEach(CourseFilter.allCases, id: \.self) { filter in
                            FilterChip(title: filter.displayName, isSelected: viewModel.selectedFilter == filter) {
                                viewModel.selectedFilter = filter
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
                
                // Course Grid
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if viewModel.filteredCourses.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No courses available")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // AI Recommendations Section
                            if authService.currentUser?.id != nil {
                                CourseRecommendationsView()
                                    .padding(.horizontal)
                            }
                            
                            // Course Grid
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ForEach(viewModel.filteredCourses) { course in
                                    NavigationLink(destination: CourseDetailView(course: course)) {
                                        CourseCatalogCard(course: course, enrollment: viewModel.enrollments.first(where: { $0.courseId == course.id }))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color.dashboardBg)
            .navigationTitle("Discover Courses")
            .task {
                if let userId = authService.currentUser?.id {
                    await viewModel.loadCourses(learnerId: userId)
                }
            }
        }
    }
}

struct CourseCatalogCard: View {
    let course: Course
    let enrollment: Enrollment?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Thumbnail placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [.accentBlue.opacity(0.6), .accentPurple.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 120)
                .overlay(
                    Image(systemName: "book.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.8))
                )
            
            VStack(alignment: .leading, spacing: 6) {
                Text(course.title)
                    .font(.headline)
                    .foregroundColor(.dashboardTextPrimary)
                    .lineLimit(2)
                
                Text(course.courseDescription)
                    .font(.caption)
                    .foregroundColor(.dashboardTextSecondary)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Label("\(course.durationHours)h", systemImage: "clock")
                        .font(.caption2)
                        .foregroundColor(.dashboardTextSecondary)
                    
                    Text(enrollmentStatusText)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(enrollmentStatusColor.opacity(0.2))
                        .foregroundColor(enrollmentStatusColor)
                        .cornerRadius(4)
                }
            }
        }
        .padding()
        .background(Color.dashboardCard)
        .cornerRadius(16)
    }
    
    private var enrollmentStatusText: String {
        guard let enrollment = enrollment else {
            return "Not Enrolled"
        }
        
        if enrollment.status == .completed || enrollment.completionPercentage >= 100 {
            return "Completed"
        } else if enrollment.completionPercentage > 0 {
            return "In Progress"
        } else {
            return "Enrolled"
        }
    }
    
    private var enrollmentStatusColor: Color {
        guard let enrollment = enrollment else {
            return .gray
        }
        
        if enrollment.status == .completed || enrollment.completionPercentage >= 100 {
            return .green
        } else if enrollment.completionPercentage > 0 {
            return .orange
        } else {
            return .blue
        }
    }
}

// MARK: - My Courses View

@MainActor
class MyCoursesViewModel: ObservableObject {
    @Published var enrollments: [Enrollment] = []
    @Published var courses: [Course] = []
    @Published var isLoading = false
    
    func loadEnrollments(learnerId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            enrollments = try await ContentService.shared.fetchEnrollmentsByLearner(learnerId: learnerId)
            
            // Load course details for each enrollment
            for enrollment in enrollments {
                if let course = try? await CourseService.shared.fetchCourse(id: enrollment.courseId) {
                    courses.append(course)
                }
            }
        } catch {
            print("Error loading enrollments: \(error)")
        }
    }
}

struct MyCoursesView: View {
    @StateObject private var authService = SupabaseAuthService.shared
    @StateObject private var viewModel = MyCoursesViewModel()
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.courses.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No Enrolled Courses")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Explore the catalog to find courses")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(Array(zip(viewModel.courses, viewModel.enrollments)), id: \.0.id) { course, enrollment in
                                EnrolledCourseCard(course: course, enrollment: enrollment)
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color.dashboardBg)
            .navigationTitle("My Courses")
            .task {
                if let userId = authService.currentUser?.id {
                    await viewModel.loadEnrollments(learnerId: userId)
                }
            }
        }
    }
}

struct EnrolledCourseCard: View {
    let course: Course
    let enrollment: Enrollment
    
    var body: some View {
        NavigationLink {
            CourseContentView(course: course)
        } label: {
            cardContent
        }
        .buttonStyle(.plain)
    }
    
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(course.title)
                        .font(.headline)
                    
                    Text(course.courseDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            
            // Progress Bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Progress")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(enrollment.completionPercentage))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.ltmsPrimary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.ltmsPrimary)
                            .frame(width: geometry.size.width * (enrollment.completionPercentage / 100))
                    }
                }
                .frame(height: 8)
            }
            
            HStack {
                Label("\(course.durationHours)h", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Continue Learning")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.ltmsPrimary)
            }
        }
        .padding()
        .background(Color.dashboardCard)
        .cornerRadius(16)
    }
}

// MARK: - Progress View

@MainActor
class LearnerProgressViewModel: ObservableObject {
    @Published var statistics: LearningStatistics?
    @Published var streak: LearningStreak?
    @Published var insights: [String] = []
    @Published var activities: [LearnerActivity] = []
    @Published var isLoading = false
    
    func loadProgressData(userId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Load statistics
            statistics = try await ProgressAnalyticsService.shared.getLearningStatistics(userId: userId)
            
            // Load streak
            streak = try await ProgressAnalyticsService.shared.getLearningStreak(userId: userId)
            
            // Load activities
            activities = try await ProgressAnalyticsService.shared.getRecentActivities(userId: userId, limit: 10)
            
            // Generate insights
            if let stats = statistics {
                insights = await AIFeedbackService.shared.generateLearningInsights(statistics: stats)
            }
        } catch {
            print("Error loading progress data: \(error)")
        }
    }
}

struct LearnerProgressView: View {
    @StateObject private var viewModel = LearnerProgressViewModel()
    @StateObject private var authService = SupabaseAuthService.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.dashboardBg.ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.accentBlue)
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Statistics Cards
                            if let stats = viewModel.statistics {
                                statisticsSection(stats: stats)
                            }
                            
                            // Learning Streak
                            if let streak = viewModel.streak {
                                streakSection(streak: streak)
                            }
                            
                            // AI Insights
                            if !viewModel.insights.isEmpty {
                                insightsSection
                            }
                            
                            // Activity Timeline
                            if !viewModel.activities.isEmpty {
                                LearnerActivityTimeline(activities: viewModel.activities)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("My Progress")
            .navigationBarTitleDisplayMode(.large)
            .task {
                if let userId = authService.currentUser?.id {
                    await viewModel.loadProgressData(userId: userId)
                }
            }
        }
    }
    
    // MARK: - Statistics Section
    
    private func statisticsSection(stats: LearningStatistics) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Learning Statistics")
                .font(.headline)
                .foregroundColor(.dashboardTextPrimary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ProgressStatCard(
                    title: "Courses",
                    value: "\(stats.totalCoursesEnrolled)",
                    subtitle: "\(stats.coursesCompleted) completed",
                    icon: "book.fill",
                    color: .accentBlue
                )
                
                ProgressStatCard(
                    title: "Time Spent",
                    value: stats.formattedTotalTime,
                    subtitle: "Learning time",
                    icon: "clock.fill",
                    color: .accentPurple
                )
                
                ProgressStatCard(
                    title: "Quizzes",
                    value: "\(stats.quizzesTaken)",
                    subtitle: "\(stats.quizzesPassed) passed",
                    icon: "graduationcap.fill",
                    color: .green
                )
                
                ProgressStatCard(
                    title: "Avg Score",
                    value: "\(Int(stats.averageQuizScore))%",
                    subtitle: "Quiz average",
                    icon: "chart.bar.fill",
                    color: .orange
                )
            }
        }
    }
    
    // MARK: - Streak Section
    
    private func streakSection(streak: LearningStreak) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Learning Streak")
                        .font(.headline)
                        .foregroundColor(.dashboardTextPrimary)
                    
                    Text(streak.statusMessage)
                        .font(.subheadline)
                        .foregroundColor(.dashboardTextSecondary)
                }
                
                Spacer()
            }
            
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("\(streak.currentStreak)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.orange)
                    
                    Text("Current")
                        .font(.caption)
                        .foregroundColor(.dashboardTextSecondary)
                }
                
                Divider()
                    .frame(height: 50)
                
                VStack(spacing: 4) {
                    Text("\(streak.longestStreak)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.accentBlue)
                    
                    Text("Best")
                        .font(.caption)
                        .foregroundColor(.dashboardTextSecondary)
                }
                
                Spacer()
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.orange.opacity(0.1), Color.accentBlue.opacity(0.1)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .padding()
        .background(Color.dashboardCard)
        .cornerRadius(20)
    }
    
    // MARK: - Insights Section
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.accentPurple)
                Text("AI Insights")
                    .font(.headline)
                    .foregroundColor(.dashboardTextPrimary)
            }
            
            ForEach(viewModel.insights, id: \.self) { insight in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.accentBlue)
                        .font(.caption)
                    
                    Text(insight)
                        .font(.subheadline)
                        .foregroundColor(.dashboardTextPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.dashboardCardAlt.opacity(0.5))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.dashboardCard)
        .cornerRadius(20)
    }
}

// MARK: - Progress Stat Card Component

struct ProgressStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.dashboardTextPrimary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.dashboardTextSecondary)
                    .textCase(.uppercase)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.dashboardTextSecondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.dashboardCard, Color.dashboardCard.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
    }
}

// MARK: - Profile View

struct LearnerProfileView: View {
    @StateObject private var authService = SupabaseAuthService.shared
    @StateObject private var themeManager = ThemeManager.shared
    @State private var showLogoutAlert = false
    @State private var showEditProfile = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.dashboardBg.ignoresSafeArea()
                
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
                                        Text(authService.currentUser?.fullName ?? "")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.dashboardTextPrimary)
                                        
                                        Text(authService.currentUser?.email ?? "")
                                            .font(.subheadline)
                                            .foregroundColor(.dashboardTextSecondary)
                                        
                                        // Role Badge
                                        HStack(spacing: 4) {
                                            Image(systemName: "graduationcap.fill")
                                                .font(.caption2)
                                            Text("Learner")
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
                                ProfileInfoRow(
                                    icon: "person.fill",
                                    label: "Full Name",
                                    value: authService.currentUser?.fullName ?? "Not set"
                                )
                                
                                Divider()
                                    .padding(.leading, 52)
                                
                                ProfileInfoRow(
                                    icon: "envelope.fill",
                                    label: "Email",
                                    value: authService.currentUser?.email ?? "Not set"
                                )
                                
                                Divider()
                                    .padding(.leading, 52)
                                
                                ProfileInfoRow(
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
                            
                            VStack(spacing: 12) {
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
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                        
                        // Account Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Account")
                                .font(.headline)
                                .foregroundColor(.dashboardTextPrimary)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                // Sign Out Button
                                Button {
                                    showLogoutAlert = true
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
                                    .cornerRadius(12)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
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
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
            }
        }
    }
}

// MARK: - Supporting Views

struct StatisticCard: View {
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

struct ProfileInfoRow: View {
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
    LearnerDashboardView()
}
