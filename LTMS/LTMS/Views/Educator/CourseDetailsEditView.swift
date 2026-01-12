//
//  CourseDetailsEditView.swift
//  LTMS
//
//  Created for Prerequisites and Learning Objectives feature
//

import SwiftUI

struct CourseDetailsEditView: View {
    let course: Course
    var onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var prerequisites: [String]
    @State private var learningObjectives: [String]
    @State private var newPrerequisite = ""
    @State private var newObjective = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    init(course: Course, onSave: @escaping () -> Void) {
        self.course = course
        self.onSave = onSave
        _prerequisites = State(initialValue: course.prerequisites ?? [])
        _learningObjectives = State(initialValue: course.learningObjectives ?? [])
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Prerequisites Section
                Section {
                    ForEach(prerequisites.indices, id: \.self) { index in
                        HStack {
                            Text("• \(prerequisites[index])")
                            Spacer()
                            Button(role: .destructive) {
                                prerequisites.remove(at: index)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    HStack {
                        TextField("Add prerequisite", text: $newPrerequisite)
                        Button("Add") {
                            if !newPrerequisite.isEmpty {
                                prerequisites.append(newPrerequisite)
                                newPrerequisite = ""
                            }
                        }
                        .disabled(newPrerequisite.isEmpty)
                    }
                } header: {
                    Text("Prerequisites")
                } footer: {
                    Text("What students should know before taking this course")
                }
                
                // Learning Objectives Section
                Section {
                    ForEach(learningObjectives.indices, id: \.self) { index in
                        HStack {
                            Text("• \(learningObjectives[index])")
                            Spacer()
                            Button(role: .destructive) {
                                learningObjectives.remove(at: index)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    HStack {
                        TextField("Add learning objective", text: $newObjective)
                        Button("Add") {
                            if !newObjective.isEmpty {
                                learningObjectives.append(newObjective)
                                newObjective = ""
                            }
                        }
                        .disabled(newObjective.isEmpty)
                    }
                } header: {
                    Text("Learning Objectives")
                } footer: {
                    Text("What students will learn by completing this course")
                }
                
                // Save Button
                Section {
                    Button(action: saveCourseDetails) {
                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            Text("Save Changes")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isLoading)
                }
            }
            .navigationTitle("Course Details")
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
        }
    }
    
    private func saveCourseDetails() {
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
                updatedCourse.prerequisites = prerequisites.isEmpty ? nil : prerequisites
                updatedCourse.learningObjectives = learningObjectives.isEmpty ? nil : learningObjectives
                updatedCourse.updatedAt = Date()
                
                // Update in Supabase
                _ = try await SupabaseService.shared.update(updatedCourse, id: courseId, in: SupabaseConstants.courses)
                
                print("✅ Course details updated successfully!")
                onSave()
                dismiss()
            } catch {
                print("❌ Error updating course details: \(error)")
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

#Preview {
    CourseDetailsEditView(course: Course(
        id: "1",
        organizationId: "test",
        title: "Test Course",
        courseDescription: "Test",
        level: .beginner,
        durationHours: 10,
        thumbnailURL: nil,
        isPublished: false,
        createdById: "admin",
        assignedEducatorId: nil,
        prerequisites: ["Basic programming"],
        learningObjectives: ["Learn Swift"],
        createdAt: Date(),
        updatedAt: Date()
    )) {
        print("Saved")
    }
}
