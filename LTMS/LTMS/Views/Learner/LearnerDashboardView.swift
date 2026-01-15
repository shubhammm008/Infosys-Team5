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
    
    init() {
        // Configure tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.dashboardCard)
        
        // Selected item color
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.accentBlue)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color.accentBlue)
        ]
        
        // Normal item color
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.dashboardTextSecondary)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Color.dashboardTextSecondary)
        ]
        
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
    @StateObject private var authService = SupabaseAuthService.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dark gradient background
                Rectangle()
                    .fill(Color.dashboardBg)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Greeting Header
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(greetingMessage)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.dashboardTextPrimary)
                                
                                Text(authService.currentUser?.firstName ?? "Learner")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.dashboardTextPrimary)
                                
                                Text(formattedDate)
                                    .font(.subheadline)
                                    .foregroundColor(.dashboardTextSecondary)
                            }
                            
                            Spacer()
                            
                            // Profile Avatar
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
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.accentBlue, lineWidth: 2)
                                            )
                                    default:
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [.accentBlue, .accentPurple],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 50, height: 50)
                                            .overlay(
                                                Image(systemName: "person.fill")
                                                    .foregroundColor(.white)
                                                    .font(.system(size: 20))
                                            )
                                    }
                                }
                                .id(profilePictureURL)
                            } else {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.accentBlue, .accentPurple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.white)
                                            .font(.system(size: 20))
                                    )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        
                        // Search Bar
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.dashboardTextSecondary)
                            TextField("Search courses...", text: $viewModel.searchText)
                                .foregroundColor(.dashboardTextPrimary)
                                .tint(.accentBlue)
                        }
                        .padding(16)
                        .background(Color.dashboardCard)
                        .cornerRadius(12)
                        .padding(.horizontal, 16)
                        
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
                            .padding(.horizontal, 16)
                        }
                        
                        // Course Grid
                        if viewModel.isLoading {
                            VStack {
                                Spacer()
                                ProgressView()
                                    .tint(.accentBlue)
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
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            // DISABLED - Causes FirebaseService crash
            // .task {
            //     await viewModel.loadCourses()
            // }
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
            return "Hello,"
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM"
        return formatter.string(from: Date())
    }
}

struct CourseCatalogCard: View {
    let course: Course
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Thumbnail with gradient overlay
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [.accentBlue, .accentPurple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 120)
                .overlay(
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "book.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white.opacity(0.3))
                                .padding(16)
                        }
                    }
                )
            
            VStack(alignment: .leading, spacing: 8) {
                Text(course.title)
                    .font(.headline)
                    .foregroundColor(.dashboardTextPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
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
                        .background(levelColor.opacity(0.3))
                        .foregroundColor(levelColor)
                        .cornerRadius(6)
                }
            }
        }
        .padding(12)
        .background(Color.dashboardCard)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
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
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Progress tracking coming soon")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .background(Color.ltmsBackground)
            .navigationTitle("My Progress")
        }
    }
}

// MARK: - Profile View

struct LearnerProfileView: View {
    @StateObject private var authService = SupabaseAuthService.shared
    @State private var showLogoutAlert = false
    @State private var showEditProfile = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dark gradient background
                Rectangle()
                    .fill(Color.dashboardBg)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // MARK: - Profile Header Card
                        VStack(spacing: 16) {
                            // Avatar
                            if let profilePictureURL = authService.currentUser?.profilePictureURL,
                               let url = URL(string: profilePictureURL) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(width: 90, height: 90)
                                            .tint(.accentBlue)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 90, height: 90)
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle()
                                                    .stroke(
                                                        LinearGradient(
                                                            colors: [.accentBlue, .accentPurple],
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        ),
                                                        lineWidth: 3
                                                    )
                                            )
                                    case .failure(_):
                                        // Show default avatar on failure
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [.accentBlue, .accentPurple],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 90, height: 90)
                                            .overlay(
                                                Image(systemName: "person.fill")
                                                    .font(.system(size: 40))
                                                    .foregroundColor(.white)
                                            )
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                .id(profilePictureURL) // Force refresh when URL changes
                            } else {
                                // Default avatar when no profile picture
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.accentBlue, .accentPurple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 90, height: 90)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(.white)
                                    )
                            }
                            
                            // User Info
                            VStack(spacing: 4) {
                                Text(authService.currentUser?.fullName ?? "User")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.dashboardTextPrimary)
                                
                                Text(authService.currentUser?.email ?? "user@example.com")
                                    .font(.subheadline)
                                    .foregroundColor(.dashboardTextSecondary)
                            }
                            
                            // Edit Profile Button
                            Button(action: {
                                showEditProfile = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "pencil")
                                        .font(.subheadline)
                                    Text("Edit Profile")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        colors: [.accentBlue, .accentPurple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                            }
                        }
                        .padding(24)
                        .background(Color.dashboardCard)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 5)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        
                        // MARK: - Terms & Privacy
                        VStack(spacing: 0) {
                            NavigationLink(destination: TermsPrivacyView()) {
                                HStack(spacing: 16) {
                                    // Icon with background
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.accentBlue.opacity(0.2))
                                            .frame(width: 44, height: 44)
                                        
                                        Image(systemName: "info.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.accentBlue)
                                    }
                                    
                                    // Title
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Terms & Privacy Policy")
                                            .font(.body)
                                            .fontWeight(.medium)
                                            .foregroundColor(.dashboardTextPrimary)
                                        
                                        Text("Review our policies")
                                            .font(.caption)
                                            .foregroundColor(.dashboardTextSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    // Chevron
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.dashboardTextSecondary)
                                }
                                .padding(16)
                            }
                            .buttonStyle(.plain)
                            .background(Color.dashboardCardAlt)
                            .cornerRadius(16)
                        }
                        .padding(.horizontal, 16)
                        
                        // MARK: - Sign Out Section
                        VStack(spacing: 0) {
                            Button(action: {
                                showLogoutAlert = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.body)
                                    Text("Sign Out")
                                        .font(.body)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.dashboardCard)
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.dashboardCard, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
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
}

// MARK: - Supporting Components

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
}

struct ProfileMenuItem: View {
    let icon: String
    let iconColor: Color
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon with background
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(iconColor)
                }
                
                // Title
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct ProfileMenuItemWithDetail: View {
    let icon: String
    let iconColor: Color
    let title: String
    let detail: String
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 16) {
                // Icon with background
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(iconColor)
                }
                
                // Title
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Detail
                Text(detail)
                    .font(.body)
                    .foregroundColor(.secondary)
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct ProfileMenuItemWithToggle: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon with background
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
            }
            
            // Title
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            // Toggle
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct ProfileMenuItemWithBadge: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let badgeCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon with background
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(iconColor)
                }
                
                // Title and Subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Badge
                if badgeCount > 0 {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 24, height: 24)
                        
                        Text("\(badgeCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    LearnerDashboardView()
}
