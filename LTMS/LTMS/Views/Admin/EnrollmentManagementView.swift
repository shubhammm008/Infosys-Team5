//
//  EnrollmentManagementView.swift
//  LTMS
//
//  Created by Shubham Singh on 13/01/26.
//

import SwiftUI
import Combine

@MainActor
class EnrollmentManagementViewModel: ObservableObject {
    @Published var courses: [Course] = []
    @Published var selectedCourse: Course?
    @Published var enrollmentDetails: [(enrollment: Enrollment, user: User)] = []
    @Published var availableUsers: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showAddEnrollmentSheet = false
    @Published var selectedUserToEnroll: User?
    @Published var searchText = ""
    
    private let analyticsService = AnalyticsService()
    private let supabaseService = SupabaseService.shared
    
    func loadCourses(organizationId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            courses = try await supabaseService.queryMultiple(
                from: SupabaseConstants.courses,
                filters: [("organization_id", organizationId)]
            )
        } catch {
            errorMessage = "Failed to load courses: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadEnrollments(courseId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            enrollmentDetails = try await analyticsService.fetchEnrollmentDetails(courseId: courseId)
        } catch {
            errorMessage = "Failed to load enrollments: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadAvailableUsers(organizationId: String) async {
        do {
            let allUsers: [User] = try await supabaseService.queryMultiple(
                from: SupabaseConstants.users,
                filters: [("organization_id", organizationId), ("role", UserRole.learner.rawValue)]
            )
            
            // Filter out already enrolled users
            let enrolledUserIds = Set(enrollmentDetails.map { $0.user.id ?? "" })
            availableUsers = allUsers.filter { user in
                guard let userId = user.id else { return false }
                return !enrolledUserIds.contains(userId)
            }
        } catch {
            errorMessage = "Failed to load users: \(error.localizedDescription)"
        }
    }
    
    func enrollUser(userId: String, courseId: String, adminId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await analyticsService.enrollUserInCourse(
                userId: userId,
                courseId: courseId,
                enrolledBy: adminId
            )
            
            // Reload enrollments
            await loadEnrollments(courseId: courseId)
            showAddEnrollmentSheet = false
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func unenrollUser(enrollmentId: String, courseId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await analyticsService.unenrollUser(enrollmentId: enrollmentId)
            await loadEnrollments(courseId: courseId)
        } catch {
            errorMessage = "Failed to unenroll user: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func updateEnrollmentStatus(enrollmentId: String, status: EnrollmentStatus, courseId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await analyticsService.updateEnrollmentStatus(enrollmentId: enrollmentId, status: status)
            await loadEnrollments(courseId: courseId)
        } catch {
            errorMessage = "Failed to update status: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    var filteredEnrollments: [(enrollment: Enrollment, user: User)] {
        guard !searchText.isEmpty else { return enrollmentDetails }
        
        return enrollmentDetails.filter { detail in
            detail.user.fullName.localizedCaseInsensitiveContains(searchText) ||
            detail.user.email.localizedCaseInsensitiveContains(searchText)
        }
    }
}

struct EnrollmentManagementView: View {
    @StateObject private var viewModel = EnrollmentManagementViewModel()
    @EnvironmentObject var authService: SupabaseAuthService
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Course selector
                if !viewModel.courses.isEmpty {
                    courseSelectionSection
                }
                
                if viewModel.selectedCourse != nil {
                    Divider()
                    enrollmentListSection
                }
                
                Spacer()
            }
            .navigationTitle("Enrollment Management")
            .toolbar {
                if viewModel.selectedCourse != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            Task {
                                await viewModel.loadAvailableUsers(organizationId: authService.currentUser?.organizationId ?? "")
                                viewModel.showAddEnrollmentSheet = true
                            }
                        }) {
                            Label("Add Enrollment", systemImage: "person.badge.plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showAddEnrollmentSheet) {
                addEnrollmentSheet
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .task {
                if let organizationId = authService.currentUser?.organizationId {
                    await viewModel.loadCourses(organizationId: organizationId)
                }
            }
        }
    }
    
    private var courseSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Course")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.courses) { course in
                        CourseSelectionCard(
                            course: course,
                            isSelected: viewModel.selectedCourse?.id == course.id
                        )
                        .onTapGesture {
                            viewModel.selectedCourse = course
                            if let courseId = course.id {
                                Task {
                                    await viewModel.loadEnrollments(courseId: courseId)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom)
        }
    }
    
    private var enrollmentListSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search learners...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                
                if !viewModel.searchText.isEmpty {
                    Button(action: { viewModel.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            
            // Stats header
            if let course = viewModel.selectedCourse {
                HStack(spacing: 20) {
                    StatBox(
                        title: "Total Enrolled",
                        value: "\(viewModel.enrollmentDetails.count)",
                        color: .blue
                    )
                    
                    if let maxEnrollments = course.maxEnrollments {
                        StatBox(
                            title: "Capacity",
                            value: "\(viewModel.enrollmentDetails.count)/\(maxEnrollments)",
                            color: .orange
                        )
                    }
                    
                    StatBox(
                        title: "Completed",
                        value: "\(viewModel.enrollmentDetails.filter { $0.enrollment.status == .completed }.count)",
                        color: .green
                    )
                    
                    StatBox(
                        title: "Active",
                        value: "\(viewModel.enrollmentDetails.filter { $0.enrollment.status == .active }.count)",
                        color: .purple
                    )
                }
                .padding()
            }
            
            Divider()
            
            // Enrollment list
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredEnrollments.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "person.3.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text(viewModel.searchText.isEmpty ? "No enrollments yet" : "No matching learners found")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.filteredEnrollments, id: \.enrollment.id) { detail in
                        EnrollmentRow(
                            enrollment: detail.enrollment,
                            user: detail.user,
                            onUnenroll: {
                                if let enrollmentId = detail.enrollment.id,
                                   let courseId = viewModel.selectedCourse?.id {
                                    Task {
                                        await viewModel.unenrollUser(enrollmentId: enrollmentId, courseId: courseId)
                                    }
                                }
                            },
                            onStatusChange: { newStatus in
                                if let enrollmentId = detail.enrollment.id,
                                   let courseId = viewModel.selectedCourse?.id {
                                    Task {
                                        await viewModel.updateEnrollmentStatus(
                                            enrollmentId: enrollmentId,
                                            status: newStatus,
                                            courseId: courseId
                                        )
                                    }
                                }
                            }
                        )
                    }
                }
                .listStyle(.plain)
            }
        }
    }
    
    private var addEnrollmentSheet: some View {
        NavigationView {
            List {
                if viewModel.availableUsers.isEmpty {
                    Text("All learners are already enrolled in this course")
                        .foregroundColor(.gray)
                        .italic()
                } else {
                    ForEach(viewModel.availableUsers) { user in
                        Button(action: {
                            if let userId = user.id,
                               let courseId = viewModel.selectedCourse?.id,
                               let adminId = authService.currentUser?.id {
                                Task {
                                    await viewModel.enrollUser(
                                        userId: userId,
                                        courseId: courseId,
                                        adminId: adminId
                                    )
                                }
                            }
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(user.fullName)
                                        .font(.headline)
                                    Text(user.email)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Enrollment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.showAddEnrollmentSheet = false
                    }
                }
            }
        }
    }
}

struct CourseSelectionCard: View {
    let course: Course
    let isSelected: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(course.title)
                .font(.headline)
                .lineLimit(2)
            
            HStack {
                Label(course.level.displayName, systemImage: "chart.bar")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .frame(width: 200, height: 80)
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .cornerRadius(12)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct EnrollmentRow: View {
    let enrollment: Enrollment
    let user: User
    let onUnenroll: () -> Void
    let onStatusChange: (EnrollmentStatus) -> Void
    
    @State private var showingStatusPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.fullName)
                        .font(.headline)
                    Text(user.email)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    StatusBadge(status: enrollment.status)
                    
                    Text("\(Int(enrollment.completionPercentage))% Complete")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            HStack(spacing: 16) {
                Label(formatDate(enrollment.enrollmentDate), systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if let lastAccessed = enrollment.lastAccessed {
                    Label("Last: \(formatDate(lastAccessed))", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                if let enrolledBy = enrollment.enrolledBy, enrolledBy != "self" {
                    Label("Admin enrolled", systemImage: "person.badge.key")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                Menu {
                    Button(action: { showingStatusPicker = true }) {
                        Label("Change Status", systemImage: "arrow.triangle.2.circlepath")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: onUnenroll) {
                        Label("Unenroll", systemImage: "person.crop.circle.badge.minus")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 8)
        .confirmationDialog("Change Enrollment Status", isPresented: $showingStatusPicker) {
            ForEach(EnrollmentStatus.allCases, id: \.self) { status in
                Button(status.displayName) {
                    onStatusChange(status)
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct StatusBadge: View {
    let status: EnrollmentStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(4)
    }
    
    private var backgroundColor: Color {
        switch status {
        case .active:
            return .blue
        case .completed:
            return .green
        case .dropped:
            return .gray
        }
    }
}

#Preview {
    EnrollmentManagementView()
        .environmentObject(SupabaseAuthService.shared)
}
