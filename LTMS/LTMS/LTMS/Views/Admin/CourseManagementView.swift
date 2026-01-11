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
                        .foregroundColor(.secondary)
                    TextField("Search courses...", text: $viewModel.searchText)
                }
                .padding()
                .background(Color.ltmsCardBackground)
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
                            .foregroundColor(.secondary)
                        Text("No courses found")
                            .font(.headline)
                            .foregroundColor(.secondary)
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
            .background(Color.ltmsBackground)
            .navigationTitle("Course Management")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateCourse = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
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
                        .foregroundColor(.secondary)
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
                        .foregroundColor(.secondary)
                }
            }
            
            // Assigned Educator
            if let educatorId = course.assignedEducatorId,
               let educator = MockDataService.shared.getUserByEmail(educatorId) ?? MockDataService.shared.getUsers().first(where: { $0.id == educatorId }) {
                HStack(spacing: 8) {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.purple)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Assigned to:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(educator.fullName)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Course Details
            HStack(spacing: 16) {
                Label("\(course.durationHours)h", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
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
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(6)
                } else {
                    Text("Draft")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(6)
                }
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
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }
}

#Preview {
    CourseManagementView()
}
