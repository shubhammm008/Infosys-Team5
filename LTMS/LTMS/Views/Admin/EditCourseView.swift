//
//  EditCourseView.swift
//  LTMS
//
//  Created by Shubham Singh on 08/01/26.
//

import SwiftUI

struct EditCourseView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = SupabaseAuthService.shared
    
    let course: Course
    var onUpdate: () -> Void
    
    @State private var title: String
    @State private var description: String
    @State private var selectedLevel: CourseLevel
    @State private var durationHours: Int
    @State private var isPublished: Bool
    @State private var selectedEducatorId: String?
    
    // Scheduling fields
    @State private var enableScheduling: Bool
    @State private var scheduledStartDate: Date
    @State private var scheduledEndDate: Date
    @State private var enableEnrollmentDeadline: Bool
    @State private var enrollmentDeadline: Date
    
    // Enrollment management
    @State private var enableMaxEnrollments: Bool
    @State private var maxEnrollments: Int
    @State private var isVisibleInCatalog: Bool
    
    @State private var educators: [User] = []
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    init(course: Course, onUpdate: @escaping () -> Void) {
        self.course = course
        self.onUpdate = onUpdate
        
        // Initialize state with course values
        _title = State(initialValue: course.title)
        _description = State(initialValue: course.courseDescription)
        _selectedLevel = State(initialValue: course.level)
        _durationHours = State(initialValue: course.durationHours)
        _isPublished = State(initialValue: course.isPublished)
        _selectedEducatorId = State(initialValue: course.assignedEducatorId)
        
        // Initialize scheduling
        _enableScheduling = State(initialValue: course.scheduledStartDate != nil || course.scheduledEndDate != nil)
        _scheduledStartDate = State(initialValue: course.scheduledStartDate ?? Date())
        _scheduledEndDate = State(initialValue: course.scheduledEndDate ?? Date().addingTimeInterval(86400 * 30))
        _enableEnrollmentDeadline = State(initialValue: course.enrollmentDeadline != nil)
        _enrollmentDeadline = State(initialValue: course.enrollmentDeadline ?? Date().addingTimeInterval(86400 * 7))
        
        // Initialize enrollment management
        _enableMaxEnrollments = State(initialValue: course.maxEnrollments != nil)
        _maxEnrollments = State(initialValue: course.maxEnrollments ?? 50)
        _isVisibleInCatalog = State(initialValue: course.isVisibleInCatalog)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Course Information") {
                    TextField("Course Title", text: $title)
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Picker("Level", selection: $selectedLevel) {
                        ForEach(CourseLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                    
                    Stepper("Duration: \(durationHours) hours", value: $durationHours, in: 1...500)
                }
                
                Section("Assign Educator") {
                    Picker("Educator", selection: $selectedEducatorId) {
                        Text("No Educator").tag(nil as String?)
                        ForEach(educators, id: \.id) { educator in
                            Text(educator.fullName).tag(educator.id as String?)
                        }
                    }
                    
                    if let educatorId = selectedEducatorId,
                       let educator = educators.first(where: { $0.id == educatorId }) {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.accentSecondary)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(educator.fullName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(educator.email)
                                    .font(.caption)
                                    .foregroundColor(.dashboardTextSecondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section("Publishing") {
                    Toggle("Published", isOn: $isPublished)
                    Toggle("Visible in Catalog", isOn: $isVisibleInCatalog)
                }
                
                Section {
                    Toggle("Enable Scheduling", isOn: $enableScheduling)
                    
                    if enableScheduling {
                        DatePicker("Start Date", selection: $scheduledStartDate, displayedComponents: [.date, .hourAndMinute])
                        DatePicker("End Date", selection: $scheduledEndDate, displayedComponents: [.date, .hourAndMinute])
                    }
                } header: {
                    Text("Course Scheduling")
                } footer: {
                    if enableScheduling {
                        Text("Course will only be available between the start and end dates")
                    }
                }
                
                Section {
                    Toggle("Set Enrollment Deadline", isOn: $enableEnrollmentDeadline)
                    
                    if enableEnrollmentDeadline {
                        DatePicker("Deadline", selection: $enrollmentDeadline, displayedComponents: [.date, .hourAndMinute])
                    }
                    
                    Toggle("Limit Enrollments", isOn: $enableMaxEnrollments)
                    
                    if enableMaxEnrollments {
                        Stepper("Max Enrollments: \(maxEnrollments)", value: $maxEnrollments, in: 1...1000)
                    }
                } header: {
                    Text("Enrollment Management")
                } footer: {
                    if enableMaxEnrollments {
                        Text("Course enrollment will be closed when limit is reached")
                    }
                }
                
                Section {
                    Button(action: updateCourse) {
                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            Text("Update Course")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isLoading || !isFormValid)
                }
            }
            .navigationTitle("Edit Course")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(Color.dashboardBg)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .task {
                await loadEducators()
            }
        }
    }
    
    private var isFormValid: Bool {
        !title.isEmpty && !description.isEmpty
    }
    
    private func loadEducators() async {
        do {
            // Fetch all users from Supabase
            let allUsers: [User] = try await SupabaseService.shared.fetchAll(from: SupabaseConstants.users)
            // Filter for educators only
            educators = allUsers.filter { $0.role == .educator }
            print("📚 Loaded \(educators.count) educators from Supabase for assignment")
        } catch {
            print("❌ Error loading educators: \(error)")
            educators = []
        }
    }
    
    private func updateCourse() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                guard let courseId = course.id else {
                    errorMessage = "Course ID is missing"
                    showError = true
                    return
                }
                
                var updatedCourse = course
                updatedCourse.title = title
                updatedCourse.courseDescription = description
                updatedCourse.level = selectedLevel
                updatedCourse.durationHours = durationHours
                updatedCourse.isPublished = isPublished
                updatedCourse.assignedEducatorId = selectedEducatorId
                updatedCourse.updatedAt = Date()
                updatedCourse.scheduledStartDate = enableScheduling ? scheduledStartDate : nil
                updatedCourse.scheduledEndDate = enableScheduling ? scheduledEndDate : nil
                updatedCourse.enrollmentDeadline = enableEnrollmentDeadline ? enrollmentDeadline : nil
                updatedCourse.maxEnrollments = enableMaxEnrollments ? maxEnrollments : nil
                updatedCourse.isVisibleInCatalog = isVisibleInCatalog
                
                // Update in Supabase
                _ = try await SupabaseService.shared.update(updatedCourse, id: courseId, in: SupabaseConstants.courses)
                
                print("✅ Course updated successfully in Supabase!")
                print("   Assigned to: \(selectedEducatorId ?? "No educator")")
                
                onUpdate()
                dismiss()
            } catch {
                print("❌ Error updating course: \(error)")
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

#Preview {
    EditCourseView(course: Course(
        id: "1",
        organizationId: "test",
        title: "Test Course",
        courseDescription: "Test Description",
        level: .beginner,
        durationHours: 10,
        thumbnailURL: nil,
        isPublished: false,
        createdById: "admin",
        assignedEducatorId: nil,
        createdAt: Date(),
        updatedAt: Date(),
        scheduledStartDate: nil,
        scheduledEndDate: nil,
        enrollmentDeadline: nil,
        maxEnrollments: nil,
        isVisibleInCatalog: true
    )) {
        print("Updated")
    }
}
