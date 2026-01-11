//
//  ModuleLessonEditorView.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import SwiftUI
import Combine

@MainActor
class ModuleLessonViewModel: ObservableObject {
    @Published var lessons: [Lesson] = []
    @Published var isLoading = false
    
    let module: Module
    
    init(module: Module) {
        self.module = module
    }
    
    func loadLessons() async {
        guard let moduleId = module.id else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            lessons = try await CourseService.shared.fetchLessonsByModule(moduleId: moduleId)
        } catch {
            print("Error loading lessons: \(error)")
        }
    }
    
    func createLesson(title: String, description: String, objectives: String?, prerequisites: String?) async throws {
        guard let moduleId = module.id else { return }
        
        let lesson = Lesson(
            id: nil,
            moduleId: moduleId,
            title: title,
            lessonDescription: description,
            orderIndex: lessons.count,
            learningObjectives: objectives,
            prerequisites: prerequisites,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        _ = try await CourseService.shared.createLesson(lesson)
        await loadLessons()
    }
}

struct ModuleLessonEditorView: View {
    @StateObject private var viewModel: ModuleLessonViewModel
    @State private var showAddLesson = false
    
    init(module: Module) {
        _viewModel = StateObject(wrappedValue: ModuleLessonViewModel(module: module))
    }
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.module.title)
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text(viewModel.module.moduleDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            
            Section {
                if viewModel.lessons.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No lessons yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Button("Add First Lesson") {
                            showAddLesson = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(viewModel.lessons) { lesson in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(lesson.title)
                                .font(.headline)
                            Text(lesson.lessonDescription)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                            
                            if let objectives = lesson.learningObjectives {
                                Text("Objectives: \(objectives)")
                                    .font(.caption)
                                    .foregroundColor(.ltmsPrimary)
                                    .lineLimit(1)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            } header: {
                HStack {
                    Text("Lessons")
                    Spacer()
                    Button {
                        showAddLesson = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
        }
        .navigationTitle("Module Lessons")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddLesson) {
            AddLessonView(viewModel: viewModel)
        }
        .task {
            await viewModel.loadLessons()
        }
    }
}

struct AddLessonView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ModuleLessonViewModel
    
    @State private var title = ""
    @State private var description = ""
    @State private var objectives = ""
    @State private var prerequisites = ""
    @State private var isLoading = false
    
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
                    Button("Add Lesson") {
                        Task {
                            isLoading = true
                            defer { isLoading = false }
                            try? await viewModel.createLesson(
                                title: title,
                                description: description,
                                objectives: objectives.isEmpty ? nil : objectives,
                                prerequisites: prerequisites.isEmpty ? nil : prerequisites
                            )
                            dismiss()
                        }
                    }
                    .disabled(title.isEmpty || description.isEmpty || isLoading)
                }
            }
            .navigationTitle("Add Lesson")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ModuleLessonEditorView(module: Module(
            id: "1",
            courseId: "course1",
            title: "Introduction to SwiftUI",
            moduleDescription: "Learn the basics of SwiftUI",
            orderIndex: 0,
            createdAt: Date(),
            updatedAt: Date()
        ))
    }
}
