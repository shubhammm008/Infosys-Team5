//
//  CreateCourseView.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import SwiftUI

struct CreateCourseView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthService.shared
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedLevel: CourseLevel = .beginner
    @State private var durationHours = 10
    @State private var isPublished = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
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
                
                Section("Publishing") {
                    Toggle("Publish Immediately", isOn: $isPublished)
                }
                
                Section {
                    Button(action: createCourse) {
                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            Text("Create Course")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isLoading || !isFormValid)
                }
            }
            .navigationTitle("Create New Course")
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
    
    private var isFormValid: Bool {
        !title.isEmpty && !description.isEmpty
    }
    
    private func createCourse() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                let course = Course(
                    id: UUID().uuidString,
                    organizationId: authService.currentUser?.organizationId,
                    title: title,
                    courseDescription: description,
                    level: selectedLevel,
                    durationHours: durationHours,
                    thumbnailURL: nil,
                    isPublished: isPublished,
                    createdById: authService.currentUser?.id ?? "",
                    assignedEducatorId: nil,
                    createdAt: Date(),
                    updatedAt: Date()
                )
                
                _ = try await CourseService.shared.createCourse(course)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

#Preview {
    CreateCourseView()
}
