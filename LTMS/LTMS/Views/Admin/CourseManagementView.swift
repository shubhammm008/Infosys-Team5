//
//  CourseManagementView.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import SwiftUI
import Combine

@MainActor
class CourseManagementViewModel: ObservableObject {
    @Published var courses: [Course] = []
    @Published var isLoading = false
    @Published var searchText = ""
    
    var filteredCourses: [Course] {
        if searchText.isEmpty {
            return courses
        }
        return courses.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.courseDescription.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    func fetchCourses() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Load from Supabase
            courses = try await SupabaseService.shared.fetchAll(from: SupabaseConstants.courses)
            print("📚 Loaded \(courses.count) courses from Supabase")
        } catch {
            print("❌ Error loading courses: \(error)")
            courses = []
        }
    }
    
    func deleteCourse(id: String) async throws {
        try await SupabaseService.shared.delete(id: id, from: SupabaseConstants.courses)
        courses.removeAll { $0.id == id }
    }
}

struct CourseManagementView: View {
    @StateObject private var viewModel = CourseManagementViewModel()
    @State private var showCreateCourse = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.dashboardTextSecondary)
                    TextField("Search courses...", text: $viewModel.searchText)
                }
                .padding()
                .background(Color.dashboardCard)
                .cornerRadius(12)
                .padding()
                
                // Course List
                if viewModel.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if viewModel.filteredCourses.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "book.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.dashboardTextSecondary)
                        Text("No courses found")
                            .font(.headline)
                            .foregroundColor(.dashboardTextSecondary)
                        Button("Create Course") {
                            showCreateCourse = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.filteredCourses) { course in
                                CourseCard(course: course, viewModel: viewModel)
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color.dashboardBg)
            .navigationTitle("Course Management")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateCourse = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showCreateCourse) {
                CreateCourseView()
            }
            .task {
                await viewModel.fetchCourses()
            }
        }
    }
}

struct CourseCard: View {
    let course: Course
    @ObservedObject var viewModel: CourseManagementViewModel
    @State private var showDeleteAlert = false
    @State private var showEditSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Course Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(course.title)
                        .font(.headline)
                    
                    Text(course.courseDescription)
                        .font(.subheadline)
                        .foregroundColor(.dashboardTextSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Menu {
                    Button {
                        showEditSheet = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(.dashboardTextSecondary)
                }
            }
            
            // Assigned Educator
            if let educatorId = course.assignedEducatorId,
               let educator = MockDataService.shared.getUserByEmail(educatorId) ?? MockDataService.shared.getUsers().first(where: { $0.id == educatorId }) {
                HStack(spacing: 8) {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.accentSecondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Assigned to:")
                            .font(.caption2)
                            .foregroundColor(.dashboardTextSecondary)
                        Text(educator.fullName)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.accentSecondary.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Course Details
            HStack(spacing: 16) {
                Label("\(course.durationHours)h", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.dashboardTextSecondary)
                
                Text(course.level.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(levelColor.opacity(0.2))
                    .foregroundColor(levelColor)
                    .cornerRadius(6)
                
                if course.isPublished {
                    Text("Published")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentSuccess.opacity(0.2))
                        .foregroundColor(.accentSuccess)
                        .cornerRadius(6)
                } else {
                    Text("Draft")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentWarning.opacity(0.1))
                        .foregroundColor(.accentWarning)
                        .cornerRadius(6)
                }
                
                if !course.isVisibleInCatalog {
                    Text("Hidden")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.gray)
                        .cornerRadius(6)
                }
            }
            
            // Scheduling and Enrollment Info
            if course.isScheduled || course.maxEnrollments != nil || course.enrollmentDeadline != nil {
                VStack(alignment: .leading, spacing: 8) {
                    if let startDate = course.scheduledStartDate, let endDate = course.scheduledEndDate {
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .font(.caption)
                                .foregroundColor(.accentPrimary)
                            Text("Scheduled: \(formatDate(startDate)) - \(formatDate(endDate))")
                                .font(.caption)
                                .foregroundColor(.dashboardTextSecondary)
                        }
                        
                        if !course.isCurrentlyAvailable && course.isPublished {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption2)
                                Text(availabilityStatus)
                                    .font(.caption2)
                            }
                            .foregroundColor(.accentWarning)
                        }
                    }
                    
                    if let maxEnrollments = course.maxEnrollments {
                        HStack(spacing: 8) {
                            Image(systemName: "person.2.fill")
                                .font(.caption)
                                .foregroundColor(.accentSecondary)
                            Text("Max Enrollments: \(maxEnrollments)")
                                .font(.caption)
                                .foregroundColor(.dashboardTextSecondary)
                        }
                    }
                    
                    if let deadline = course.enrollmentDeadline {
                        HStack(spacing: 8) {
                            Image(systemName: "hourglass")
                                .font(.caption)
                                .foregroundColor(deadline > Date() ? .accentSuccess : .accentSecondary)
                            Text("Enrollment \(course.enrollmentStatus): \(formatDate(deadline))")
                                .font(.caption)
                                .foregroundColor(.dashboardTextSecondary)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.ltmsCardBackground)
        .cornerRadius(16)
        .alert("Delete Course", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    try? await viewModel.deleteCourse(id: course.id!)
                }
            }
        } message: {
            Text("Are you sure you want to delete \(course.title)?")
        }
        .sheet(isPresented: $showEditSheet) {
            EditCourseView(course: course) {
                Task {
                    await viewModel.fetchCourses()
                }
            }
        }
    }
    
    private var levelColor: Color {
        switch course.level {
        case .beginner: return .accentSuccess
        case .intermediate: return .accentWarning
        case .advanced: return .accentSecondary
        }
    }
    
    private var availabilityStatus: String {
        guard let start = course.scheduledStartDate, let end = course.scheduledEndDate else {
            return ""
        }
        
        let now = Date()
        if start > now {
            return "Starts \(formatDate(start))"
        } else if end < now {
            return "Ended"
        }
        return "Available"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

#Preview {
    CourseManagementView()
}
