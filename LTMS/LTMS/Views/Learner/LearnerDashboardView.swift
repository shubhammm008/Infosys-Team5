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
            
            LearnerProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
                .tag(3)
        }
        .tint(.ltmsPrimary)
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
                    // Show all enrolled courses (any status except dropped)
                    return enrollment.status != .dropped
                case .inProgress:
                    // Show courses that are active and have progress > 0 but < 100
                    return enrollment.status == .active && enrollment.completionPercentage > 0 && enrollment.completionPercentage < 100
                case .completed:
                    // Show completed courses
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
            courses = try await CourseService.shared.fetchPublishedCourses()
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
                .background(Color.ltmsCardBackground)
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
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(viewModel.filteredCourses) { course in
                                NavigationLink(destination: CourseDetailView(course: course)) {
                                    CourseCatalogCard(course: course, enrollment: viewModel.enrollments.first(where: { $0.courseId == course.id }))
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
        .background(Color.ltmsCardBackground)
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

