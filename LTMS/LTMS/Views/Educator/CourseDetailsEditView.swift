

import SwiftUI

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
            ZStack {
                Color.dashboardBg.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button("Cancel") { dismiss() }
                            .foregroundColor(.dashboardTextSecondary)
                        Spacer()
                        Text("Course Details")
                            .font(.headline)
                            .foregroundColor(.dashboardTextPrimary)
                        Spacer()
                        // Invisible spacer for balance
                        Button("Cancel") { }
                            .opacity(0)
                            .accessibilityHidden(true)
                    }
                    .padding()
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Prerequisites Section
                            VStack(alignment: .leading, spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Prerequisites")
                                        .font(.headline)
                                        .foregroundColor(.dashboardTextSecondary)
                                    Text("What students should know before taking this course")
                                        .font(.caption)
                                        .foregroundColor(.dashboardTextSecondary.opacity(0.7))
                                }
                                
                                VStack(spacing: 12) {
                                    ForEach(prerequisites.indices, id: \.self) { index in
                                        HStack {
                                            Text("• \(prerequisites[index])")
                                                .foregroundColor(.dashboardTextPrimary)
                                            Spacer()
                                            Button {
                                                prerequisites.remove(at: index)
                                            } label: {
                                                Image(systemName: "trash")
                                                    .foregroundColor(.red.opacity(0.8))
                                            }
                                        }
                                        .padding()
                                        .background(Color.black.opacity(0.2))
                                        .cornerRadius(12)
                                    }
                                    
                                    HStack(spacing: 12) {
                                        TextField("Add prerequisite", text: $newPrerequisite)
                                            .padding(12)
                                            .background(Color.white.opacity(0.05))
                                            .cornerRadius(12)
                                            .foregroundColor(.dashboardTextPrimary)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                            )
                                        
                                        Button("Add") {
                                            if !newPrerequisite.isEmpty {
                                                prerequisites.append(newPrerequisite)
                                                newPrerequisite = ""
                                            }
                                        }
                                        .fontWeight(.semibold)
                                        .foregroundColor(.accentBlue)
                                        .disabled(newPrerequisite.isEmpty)
                                        .opacity(newPrerequisite.isEmpty ? 0.5 : 1)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.dashboardCard)
                            .cornerRadius(20)
                            
                            // Learning Objectives Section
                            VStack(alignment: .leading, spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Learning Objectives")
                                        .font(.headline)
                                        .foregroundColor(.dashboardTextSecondary)
                                    Text("What students will learn by completing this course")
                                        .font(.caption)
                                        .foregroundColor(.dashboardTextSecondary.opacity(0.7))
                                }
                                
                                VStack(spacing: 12) {
                                    ForEach(learningObjectives.indices, id: \.self) { index in
                                        HStack {
                                            Text("• \(learningObjectives[index])")
                                                .foregroundColor(.dashboardTextPrimary)
                                            Spacer()
                                            Button {
                                                learningObjectives.remove(at: index)
                                            } label: {
                                                Image(systemName: "trash")
                                                    .foregroundColor(.red.opacity(0.8))
                                            }
                                        }
                                        .padding()
                                        .background(Color.black.opacity(0.2))
                                        .cornerRadius(12)
                                    }
                                    
                                    HStack(spacing: 12) {
                                        TextField("Add learning objective", text: $newObjective)
                                            .padding(12)
                                            .background(Color.white.opacity(0.05))
                                            .cornerRadius(12)
                                            .foregroundColor(.dashboardTextPrimary)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                            )
                                        
                                        Button("Add") {
                                            if !newObjective.isEmpty {
                                                learningObjectives.append(newObjective)
                                                newObjective = ""
                                            }
                                        }
                                        .fontWeight(.semibold)
                                        .foregroundColor(.accentBlue)
                                        .disabled(newObjective.isEmpty)
                                        .opacity(newObjective.isEmpty ? 0.5 : 1)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.dashboardCard)
                            .cornerRadius(20)
                            
                            // Save Button
                            Button(action: saveCourseDetails) {
                                ZStack {
                                    if isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("Save")
                                            .fontWeight(.bold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        colors: [Color.accentBlue, Color.accentPurple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(16)
                                .shadow(color: Color.accentBlue.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                            .disabled(isLoading)
                            .opacity(isLoading ? 0.7 : 1)
                            .padding(.vertical)
                        }
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
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
        updatedAt: Date(),
        scheduledStartDate: nil,
        scheduledEndDate: nil,
        enrollmentDeadline: nil,
        maxEnrollments: nil,
        isVisibleInCatalog: true
    )) {
        print("Saved")
    }
}
