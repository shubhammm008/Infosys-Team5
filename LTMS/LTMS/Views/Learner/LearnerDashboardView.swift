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


#Preview {
    LearnerDashboardView()
}

