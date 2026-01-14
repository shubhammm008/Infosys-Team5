//
//  EditLessonView.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import SwiftUI

struct EditLessonView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ModuleLessonViewModel
    
    let lesson: Lesson
    
    @State private var title: String
    @State private var description: String
    @State private var objectives: String
    @State private var prerequisites: String
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    init(viewModel: ModuleLessonViewModel, lesson: Lesson) {
        self.viewModel = viewModel
        self.lesson = lesson
        _title = State(initialValue: lesson.title)
        _description = State(initialValue: lesson.lessonDescription)
        _objectives = State(initialValue: lesson.learningObjectives ?? "")
        _prerequisites = State(initialValue: lesson.prerequisites ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Lesson Information") {
                    TextField("Lesson Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Learning Details") {
                    TextField("Learning Objectives (Optional)", text: $objectives, axis: .vertical)
                        .lineLimit(2...4)
                    TextField("Prerequisites (Optional)", text: $prerequisites, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section {
                    Button("Save Changes") {
                        Task {
                            isLoading = true
                            defer { isLoading = false }
                            do {
                                try await viewModel.updateLesson(
                                    lesson: lesson,
                                    title: title,
                                    description: description,
                                    objectives: objectives.isEmpty ? nil : objectives,
                                    prerequisites: prerequisites.isEmpty ? nil : prerequisites
                                )
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                showError = true
                            }
                        }
                    }
                    .disabled(title.isEmpty || description.isEmpty || isLoading)
                }
            }
            .navigationTitle("Edit Lesson")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "Failed to update lesson")
            }
        }
    }
}
