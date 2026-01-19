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
            
            
            LearnerProfileViewNew()
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
                .tag(3)
        }
        .tint(.ltmsPrimary)
    }
}

// MARK: - Course Catalog View

@MainActor
class CourseCatalogViewModel: ObservableObject {
    @Published var courses: [Course] = []
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var selectedLevel: CourseLevel?
    
    var filteredCourses: [Course] {
        var filtered = courses.filter { $0.isPublished }
        
        if let level = selectedLevel {
            filtered = filtered.filter { $0.level == level }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.courseDescription.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    func loadCourses() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            courses = try await CourseService.shared.fetchPublishedCourses()
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
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Greeting Header (matching Admin/Educator)
                    HStack(alignment: .center, spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(greetingMessage)
                                .font(.subheadline)
                                .foregroundColor(.dashboardTextSecondary)
                            
                            Text(authService.currentUser?.firstName ?? "Learner")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.dashboardTextPrimary)
                        }
                        
                        Spacer()
                        
                        // Profile Avatar - centered vertically
                        if let profilePictureURL = authService.currentUser?.profilePictureURL,
                           let url = URL(string: profilePictureURL) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 50, height: 50)
                                        .clipShape(Circle())
                                default:
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 50))
                                        .foregroundColor(.dashboardTextPrimary)
                                }
                            }
                            .id(profilePictureURL)
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.dashboardTextPrimary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // MARK: - Search Bar
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.dashboardTextSecondary)
                        TextField("", text: $viewModel.searchText, prompt: Text("Search courses...").foregroundColor(.dashboardTextSecondary))
                            .foregroundColor(.dashboardTextPrimary)
                            .tint(.accentPrimary)
                    }
                    .padding(16)
                    .background(Color.dashboardCard)
                    .cornerRadius(14)
                    
                    // MARK: - Level Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            FilterChip(title: "All", isSelected: viewModel.selectedLevel == nil) {
                                viewModel.selectedLevel = nil
                            }
                            
                            ForEach(CourseLevel.allCases, id: \.self) { level in
                                FilterChip(title: level.displayName, isSelected: viewModel.selectedLevel == level) {
                                    viewModel.selectedLevel = level
                                }
                            }
                        }
                    }
                    
                   // MARK: - Course Grid
                    if viewModel.isLoading {
                        VStack {
                            Spacer()
                            ProgressView()
                                .tint(.accentPrimary)
                            Spacer()
                        }
                        .frame(height: 300)
                    } else if viewModel.filteredCourses.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "book.closed")
                                .font(.system(size: 60))
                                .foregroundColor(.dashboardTextSecondary)
                            Text("No courses available")
                                .font(.headline)
                                .foregroundColor(.dashboardTextPrimary)
                            Text("Check back later for new content")
                                .font(.caption)
                                .foregroundColor(.dashboardTextSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(viewModel.filteredCourses) { course in
                                NavigationLink(destination: CourseDetailView(course: course)) {
                                    CourseCatalogCard(course: course)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color.dashboardBg)
            .navigationBarHidden(true)
            .task {
                await viewModel.loadCourses()
            }
        }
    }
    
    private var greetingMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            return "Good Morning,"
        case 12..<17:
            return "Good Afternoon,"
        case 17..<24:
            return "Good Evening,"
        default:
            return "Welcome Back,"
        }
    }
}

struct CourseCatalogCard: View {
    let course: Course
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Thumbnail placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [.accentPrimary, .accentSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 120)
                .overlay(
                    Image(systemName: "book.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.7))
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
                    
                    Spacer()
                    
                    Text(course.level.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(levelColor.opacity(0.2))
                        .foregroundColor(levelColor)
                        .cornerRadius(6)
                }
            }
        }
        .padding(12)
        .background(Color.dashboardCard)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
    }
    
    private var levelColor: Color {
        switch course.level {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
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
                        .tint(.accentPrimary)
                } else if viewModel.courses.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 60))
                            .foregroundColor(.dashboardTextSecondary)
                        Text("No Enrolled Courses")
                            .font(.headline)
                            .foregroundColor(.dashboardTextPrimary)
                        Text("Explore the catalog to find courses")
                            .font(.subheadline)
                            .foregroundColor(.dashboardTextSecondary)
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
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
                        .foregroundColor(.dashboardTextPrimary)
                    
                    Text(course.courseDescription)
                        .font(.subheadline)
                        .foregroundColor(.dashboardTextSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            
            // Progress Bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Progress")
                        .font(.caption)
                        .foregroundColor(.dashboardTextSecondary)
                    Spacer()
                    // Only show 100% if course status is completed
                    let displayPercentage = enrollment.status == .completed ? 100 : min(Int(enrollment.completionPercentage), 99)
                    Text("\(displayPercentage)%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(enrollment.status == .completed ? .green : .accentPrimary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [.accentPrimary, .accentSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * (enrollment.completionPercentage / 100))
                    }
                }
                .frame(height: 8)
            }
            
            HStack {
                Label("\(course.durationHours)h", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.dashboardTextSecondary)
                
                Spacer()
                
                Text("Continue Learning")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.accentPrimary)
            }
        }
        .padding(16)
        .background(Color.dashboardCard)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Progress View

struct LearnerProgressView: View {
    @StateObject private var viewModel = LearnerProgressViewModel()
    @StateObject private var authService = SupabaseAuthService.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("My Progress")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.dashboardTextPrimary)
                        
//                        Text("Track your learning journey")
//                            .font(.subheadline)
//                            .foregroundColor(.dashboardTextSecondary)
                    }
                    .padding(.top, 8)
                    
                    // Statistics Cards
                    if !viewModel.isLoading {
                        statisticsSection
                        
                        // Learning Streak
                        learningStreakSection
                        
                        // Quiz Performance
                        quizPerformanceSection
                        
                        // Recent Activity
                        recentActivitySection
                    }
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.accentPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    }
                }
                .padding()
            }
            .background(Color.dashboardBg)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.dashboardCard, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                await viewModel.loadProgressData(userId: authService.currentUser?.id ?? "")
            }
        }
    }
    
    // Rest of the implementation continues below...
    private var statisticsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                ProgressStatCard(
                    title: "Total Courses",
                    value: "\(viewModel.totalCourses)",
                    icon: "book.fill",
                    color: .blue
                )
                
                ProgressStatCard(
                    title: "Completed",
                    value: "\(viewModel.completedCourses)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
            
            HStack(spacing: 16) {
                ProgressStatCard(
                    title: "In Progress",
                    value: "\(viewModel.activeCourses)",
                    icon: "clock.fill",
                    color: .orange
                )
                
                ProgressStatCard(
                    title: "Certificates",
                    value: "\(viewModel.certificatesEarned)",
                    icon: "medal.fill",
                    color: .purple
                )
            }
        }
    }
    
    private var learningStreakSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overall Progress")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.dashboardTextPrimary)
            
            VStack(spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Average Completion")
                            .font(.subheadline)
                            .foregroundColor(.dashboardTextSecondary)
                        
                        Text("\(Int(viewModel.averageCompletion))%")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.accentPrimary)
                    }
                    
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                            .frame(width: 100, height: 100)
                        
                        Circle()
                            .trim(from: 0, to: viewModel.averageCompletion / 100)
                            .stroke(
                                LinearGradient(
                                    colors: [.accentPrimary, .accentSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))
                    }
                }
                
                Divider()
                    .background(Color.dashboardTextSecondary.opacity(0.3))
                
                HStack {
                    Image(systemName: "book.pages.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Lessons Completed")
                            .font(.caption)
                            .foregroundColor(.dashboardTextSecondary)
                        Text("\(viewModel.totalLessonsCompleted)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.dashboardTextPrimary)
                    }
                    
                    Spacer()
                }
            }
            .padding(24)
            .background(Color.dashboardCard)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
    }
    
    private var quizPerformanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quiz Performance")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.dashboardTextPrimary)
            
            if viewModel.quizSubmissions.isEmpty {
                emptyQuizStateView
            } else {
                ForEach(viewModel.quizSubmissions) { submission in
                    if let quiz = viewModel.quizzes[submission.assessmentId] {
                        QuizPerformanceCard(quiz: quiz, submission: submission)
                    }
                }
            }
        }
    }
    
    private var emptyQuizStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.questionmark")
                .font(.system(size: 40))
                .foregroundColor(.dashboardTextSecondary)
            Text("No quizzes attempted yet")
                .font(.subheadline)
                .foregroundColor(.dashboardTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.dashboardCard)
        .cornerRadius(16)
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.dashboardTextPrimary)
            
            VStack(spacing: 12) {
                ForEach(viewModel.recentActivities.prefix(5), id: \.self) { activity in
                    ActivityRow(activity: activity)
                }
                
                if viewModel.recentActivities.isEmpty {
                    Text("No recent activity")
                        .font(.subheadline)
                        .foregroundColor(.dashboardTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
            .padding(20)
            .background(Color.dashboardCard)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 50))
                .foregroundColor(.dashboardTextSecondary)
            
            Text("No courses enrolled yet")
                .font(.headline)
                .foregroundColor(.dashboardTextPrimary)
            
            Text("Start learning to see your progress")
                .font(.caption)
                .foregroundColor(.dashboardTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color.dashboardCard)
        .cornerRadius(20)
    }
}

// MARK: - Profile View

struct LearnerProfileView: View {
    @StateObject private var authService = SupabaseAuthService.shared
    @State private var showLogoutAlert = false
    @State private var showEditProfile = false
    
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
                            Text("Learner")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
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

// MARK: - Progress Supporting Views

struct ProgressStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(color)
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.dashboardTextPrimary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.dashboardTextSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.dashboardCard)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
    }
}

struct QuizPerformanceCard: View {
    let quiz: Quiz
    let submission: QuizSubmission
    
    var passed: Bool {
        submission.passed ?? false
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(passed ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: passed ? "trophy.fill" : "xmark.seal.fill")
                        .font(.system(size: 20))
                        .foregroundColor(passed ? .green : .red)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(quiz.title)
                        .font(.headline)
                        .foregroundColor(.dashboardTextPrimary)
                    Text(passed ? "Passed" : "Failed")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(passed ? .green : .red)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(submission.scoreDisplay)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(passed ? .green : .red)
                    Text("Score")
                        .font(.caption)
                        .foregroundColor(.dashboardTextSecondary)
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(passed ? Color.green : Color.red)
                        .frame(width: geometry.size.width * ((submission.score ?? 0) / 100))
                    
                    // Passing marker
                    if let passing = quiz.passingScore {
                        Rectangle()
                            .fill(Color.orange)
                            .frame(width: 2, height: 8)
                            .offset(x: geometry.size.width * (passing / 100))
                    }
                }
            }
            .frame(height: 8)
        }
        .padding(16)
        .background(Color.dashboardCard)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
    }
}
    



struct ActivityRow: View {
    let activity: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.accentPrimary.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.accentPrimary)
            }
            
            Text(activity)
                .font(.subheadline)
                .foregroundColor(.dashboardTextPrimary)
            
            Spacer()
        }
    }
}

@MainActor
class LearnerProgressViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var enrollments: [Enrollment] = []
    @Published var courses: [Course] = []
    @Published var recentActivities: [String] = []
    @Published var quizSubmissions: [QuizSubmission] = []
    @Published var quizzes: [String: Quiz] = [:] // quizId -> Quiz
    
    var totalCourses: Int {
        enrollments.count
    }
    
    var completedCourses: Int {
        enrollments.filter { $0.status == .completed }.count
    }
    
    var activeCourses: Int {
        enrollments.filter { $0.status == .active }.count
    }
    
    var certificatesEarned: Int {
        enrollments.filter { $0.certificateIssued }.count
    }
    
    var averageCompletion: Double {
        guard !enrollments.isEmpty else { return 0 }
        let total = enrollments.reduce(0.0) { $0 + $1.completionPercentage }
        return total / Double(enrollments.count)
    }
    
    var totalLessonsCompleted: Int {
        let estimate = enrollments.reduce(0) { result, enrollment in
            result + Int(enrollment.completionPercentage / 10)
        }
        return estimate
    }
    
    func loadProgressData(userId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            enrollments = try await ContentService.shared.fetchEnrollmentsByLearner(learnerId: userId)
            
            for enrollment in enrollments {
                if let courseId = enrollment.courseId as String?,
                   let course = try? await CourseService.shared.fetchCourse(id: courseId) {
                    if !courses.contains(where: { $0.id == course.id }) {
                        courses.append(course)
                    }
                }
            }
            
            
            // Fetch quiz submissions
            let submissions = try await QuizService.shared.fetchSubmissionsByUser(userId: userId)
            quizSubmissions = submissions.sorted(by: { ($0.submittedAt) > ($1.submittedAt) })
            
            // Fetch quiz details for submissions
            for submission in submissions {
                if quizzes[submission.assessmentId] == nil {
                     if let quiz = try? await QuizService.shared.fetchQuiz(id: submission.assessmentId) {
                         quizzes[submission.assessmentId] = quiz
                     }
                }
            }
            
            generateRecentActivities()
            
        } catch {
            print("Error loading progress data: \(error)")
        }
    }
    
    private func generateRecentActivities() {
        recentActivities = []
        
        let sortedEnrollments = enrollments.sorted {
            ($0.lastAccessed ?? Date.distantPast) > ($1.lastAccessed ?? Date.distantPast)
        }
        
        for enrollment in sortedEnrollments.prefix(5) {
            if let course = courses.first(where: { $0.id == enrollment.courseId }) {
                if enrollment.status == .completed {
                    recentActivities.append("Completed \(course.title)")
                } else if let lastAccessed = enrollment.lastAccessed {
                    let calendar = Calendar.current
                    if calendar.isDateInToday(lastAccessed) {
                        recentActivities.append("Studied \(course.title)")
                    }
                }
            }
        }
        
        // Add quiz activities
        for submission in quizSubmissions.prefix(3) {
            if let quiz = quizzes[submission.assessmentId] {
                let status = (submission.passed ?? false) ? "Passed" : "Attempted"
                recentActivities.append("\(status) \(quiz.title)")
            }
        }
    }
}


#Preview {
    LearnerDashboardView()
}

