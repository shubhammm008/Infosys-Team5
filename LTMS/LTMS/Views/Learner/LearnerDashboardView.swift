//
//  LearnerDashboardView.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import SwiftUI
import Combine

struct LearnerDashboardView: View {
    @StateObject private var authService = SupabaseAuthService.shared
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
            
            LearnerProfileView()
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
    @Published var selectedLevel: CourseLevel? = nil
    @Published var enrolledCourseIds: Set<String> = []
    
    init() {
        // Fetch courses on initialization
        Task {
            await fetchEnrolledCourses()
            await fetchPublishedCourses()
        }
    }
    
    func fetchEnrolledCourses() async {
        guard let userId = SupabaseAuthService.shared.currentUser?.id else { return }
        
        do {
            let enrollments = try await ContentService.shared.fetchEnrollmentsByLearner(learnerId: userId)
            enrolledCourseIds = Set(enrollments.map { $0.courseId })
            print("✅ User enrolled in \(enrolledCourseIds.count) courses")
        } catch {
            print("❌ Error loading enrollments: \(error)")
        }
    }
    
    func fetchPublishedCourses() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Fetch all courses from Supabase
            let allCourses: [Course] = try await SupabaseService.shared.fetchAll(from: SupabaseConstants.courses)
            
            // Filter for published courses only
            courses = allCourses.filter { $0.isPublished }
            
            print("📚 Loaded \(courses.count) published courses from Supabase for learners")
        } catch {
            print("❌ Error loading published courses: \(error)")
            courses = []
        }
    }
    
    var filteredCourses: [Course] {
        var filtered = courses.filter { $0.isPublished }
        
        // Exclude enrolled courses
        filtered = filtered.filter { course in
            guard let courseId = course.id else { return true }
            return !enrolledCourseIds.contains(courseId)
        }
        
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
                .background(Color.ltmsCardBackground)
                .cornerRadius(12)
                .padding()
                
                // Level Filter
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
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(viewModel.filteredCourses) { course in
                                NavigationLink(destination: CourseDetailView(course: course)) {
                                    CourseCatalogCard(course: course)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color.ltmsBackground)
            .navigationTitle("Discover Courses")
            // DISABLED - Causes FirebaseService crash
            // .task {
            //     await viewModel.loadCourses()
            // }
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
                        colors: [.ltmsPrimary.opacity(0.6), .ltmsSecondary.opacity(0.6)],
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
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                Text(course.courseDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Label("\(course.durationHours)h", systemImage: "clock")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(course.level.displayName)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(levelColor.opacity(0.2))
                        .foregroundColor(levelColor)
                        .cornerRadius(4)
                }
            }
        }
        .padding()
        .background(Color.ltmsCardBackground)
        .cornerRadius(16)
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
                                NavigationLink(destination: CourseContentView(course: course)) {
                                    EnrolledCourseCard(course: course, enrollment: enrollment)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color.ltmsBackground)
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
        .background(Color.ltmsCardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Progress View

struct LearnerProgressView: View {
    @State private var animateRings = false
    @State private var animateBars = false
    
    // Sample data - replace with real data from your services
    @State private var coursesCompleted = 4
    @State private var totalCourses = 5
    @State private var hoursLearned = 12.0
    @State private var currentStreak = 7
    @State private var weeklyHours: [Double] = [2.5, 3.0, 4.5, 2.0, 3.5, 2.5, 0.5]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(hex: "#F2F2F7")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Section
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("My Progress")
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Text("Keep it up! You're doing great.")
                                    .font(.system(size: 15, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Profile Avatar
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.white)
                                        .font(.system(size: 18))
                                )
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        // Activity Rings Card
                        ActivityRingsCard(
                            coursesCompleted: coursesCompleted,
                            totalCourses: totalCourses,
                            hoursLearned: hoursLearned,
                            currentStreak: currentStreak,
                            animateRings: animateRings
                        )
                        .padding(.horizontal)
                        
                        // Weekly Chart Card
                        WeeklyChartCard(
                            weeklyHours: weeklyHours,
                            animateBars: animateBars
                        )
                        .padding(.horizontal)
                        
                        // Achievements Section
                        AchievementsSection()
                            .padding(.horizontal)
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(.spring(response: 1.2, dampingFraction: 0.7)) {
                    animateRings = true
                }
                withAnimation(.spring(response: 1.0, dampingFraction: 0.8).delay(0.3)) {
                    animateBars = true
                }
            }
        }
    }
}

// MARK: - Activity Rings Card

struct ActivityRingsCard: View {
    let coursesCompleted: Int
    let totalCourses: Int
    let hoursLearned: Double
    let currentStreak: Int
    let animateRings: Bool
    
    var coursesProgress: Double { Double(coursesCompleted) / Double(totalCourses) }
    var hoursProgress: Double { min(hoursLearned / 20.0, 1.0) }
    var streakProgress: Double { min(Double(currentStreak) / 10.0, 1.0) }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            HStack(spacing: 30) {
                // Activity Rings
                ZStack {
                    // Outer Ring - Courses (Red)
                    Circle()
                        .stroke(Color(hex: "#FF3B30").opacity(0.2), lineWidth: 12)
                        .frame(width: 130, height: 130)
                    
                    Circle()
                        .trim(from: 0, to: animateRings ? coursesProgress : 0)
                        .stroke(Color(hex: "#FF3B30"), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 130, height: 130)
                        .rotationEffect(.degrees(-90))
                    
                    // Middle Ring - Hours (Green)
                    Circle()
                        .stroke(Color(hex: "#34C759").opacity(0.2), lineWidth: 12)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: animateRings ? hoursProgress : 0)
                        .stroke(Color(hex: "#34C759"), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                    
                    // Inner Ring - Streak (Blue)
                    Circle()
                        .stroke(Color(hex: "#007AFF").opacity(0.2), lineWidth: 12)
                        .frame(width: 70, height: 70)
                    
                    Circle()
                        .trim(from: 0, to: animateRings ? streakProgress : 0)
                        .stroke(Color(hex: "#007AFF"), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))
                }
                
                // Legend
                VStack(alignment: .leading, spacing: 16) {
                    LegendItem(
                        color: Color(hex: "#FF3B30"),
                        label: "Courses",
                        value: "\(coursesCompleted)/\(totalCourses)"
                    )
                    
                    LegendItem(
                        color: Color(hex: "#34C759"),
                        label: "Hours",
                        value: "\(Int(hoursLearned))h"
                    )
                    
                    LegendItem(
                        color: Color(hex: "#007AFF"),
                        label: "Streak",
                        value: "\(currentStreak) Days"
                    )
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            
            Text(label)
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
        .frame(maxWidth: 140)
    }
}

// MARK: - Weekly Chart Card

struct WeeklyChartCard: View {
    let weeklyHours: [Double]
    let animateBars: Bool
    let days = ["M", "T", "W", "T", "F", "S", "S"]
    let activeDay = 2 // Wednesday (0-indexed)
    
    var totalHours: Double {
        weeklyHours.reduce(0, +)
    }
    
    var maxHours: Double {
        weeklyHours.max() ?? 1
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("This Week")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("Total: \(String(format: "%.1f", totalHours))h")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.15))
                    .cornerRadius(12)
            }
            
            // Bar Chart
            HStack(alignment: .bottom, spacing: 16) {
                ForEach(0..<7) { index in
                    VStack(spacing: 8) {
                        // Bar
                        RoundedRectangle(cornerRadius: 6)
                            .fill(index == activeDay ? Color.blue : Color.blue.opacity(0.15))
                            .frame(
                                width: 32,
                                height: animateBars ? max(CGFloat(weeklyHours[index] / maxHours) * 120, 20) : 0
                            )
                        
                        // Day Label
                        Text(days[index])
                            .font(.system(size: 12, weight: index == activeDay ? .bold : .regular, design: .rounded))
                            .foregroundColor(index == activeDay ? .blue : .secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Achievements Section

struct AchievementsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Achievements")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {}) {
                    Text("See All")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.blue)
                }
            }
            
            HStack(spacing: 16) {
                AchievementCard(
                    emoji: "🔥",
                    title: "7-Day Streak",
                    backgroundColor: Color.orange.opacity(0.15)
                )
                
                AchievementCard(
                    emoji: "🎓",
                    title: "First Course",
                    backgroundColor: Color.blue.opacity(0.15)
                )
            }
        }
    }
}

struct AchievementCard: View {
    let emoji: String
    let title: String
    let backgroundColor: Color
    
    var body: some View {
        VStack(spacing: 16) {
            // Icon Container
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 70, height: 70)
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                
                Text(emoji)
                    .font(.system(size: 36))
            }
            
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(backgroundColor)
        .cornerRadius(20)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Profile View

struct LearnerProfileView: View {
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
                    Task { try? await authService.signOut() }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}

#Preview {
    LearnerDashboardView()
}
