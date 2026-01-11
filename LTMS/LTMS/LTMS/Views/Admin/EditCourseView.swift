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
                                .foregroundColor(.purple)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(educator.fullName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(educator.email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section("Publishing") {
                    Toggle("Published", isOn: $isPublished)
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
        updatedAt: Date()
    )) {
        print("Updated")
    }
}
