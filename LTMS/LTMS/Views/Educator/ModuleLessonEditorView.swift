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
    @Published var module: Module
    @Published var lessons: [Lesson] = []
    @Published var isLoading = false
    
    let courseId: String
    
    init(module: Module, courseId: String) {
        self.module = module
        self.courseId = courseId
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
    
    func updateModule(title: String, description: String) async throws {
        guard module.id != nil else { return }
        
        var updatedModule = module
        updatedModule.title = title
        updatedModule.moduleDescription = description
        updatedModule.updatedAt = Date()
        
        try await CourseService.shared.updateModule(updatedModule)
        self.module = updatedModule
    }
    
    func updateLesson(lesson: Lesson, title: String, description: String, objectives: String?, prerequisites: String?) async throws {
        guard lesson.id != nil else { return }
        
        var updatedLesson = lesson
        updatedLesson.title = title
        updatedLesson.lessonDescription = description
        updatedLesson.learningObjectives = objectives
        updatedLesson.prerequisites = prerequisites
        updatedLesson.updatedAt = Date()
        
        try await CourseService.shared.updateLesson(updatedLesson)
        await loadLessons()
    }
}

struct ModuleLessonEditorView: View {
    @StateObject private var viewModel: ModuleLessonViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showAddLesson = false
    @State private var showEditModule = false
    @State private var showEditLesson = false
    @State private var selectedLesson: Lesson?
    
    init(module: Module, courseId: String) {
        _viewModel = StateObject(wrappedValue: ModuleLessonViewModel(module: module, courseId: courseId))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.dashboardBg.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Header
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.dashboardTextPrimary)
                                .frame(width: 40, height: 40)
                                .background(Color.dashboardCard)
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Text("Module Lessons")
                            .font(.headline)
                            .foregroundColor(.dashboardTextPrimary)
                        
                        Spacer()
                        
                        // Invisible spacer for balance
                        Color.clear.frame(width: 40, height: 40)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Module Info Card
                            moduleInfoCard
                            
                            // Lessons List
                            lessonsSection
                        }
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddLesson) {
                AddLessonView(viewModel: viewModel)
            }
            .sheet(isPresented: $showEditModule) {
                EditModuleView(viewModel: viewModel)
            }
            .sheet(isPresented: $showEditLesson) {
                if let lesson = selectedLesson {
                    EditLessonView(viewModel: viewModel, lesson: lesson)
                }
            }
            .task {
                await viewModel.loadLessons()
            }
        }
    }
    
    // MARK: - Module Info Card
    private var moduleInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(viewModel.module.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.dashboardTextPrimary)
                
                Spacer()
                
                Button {
                    showEditModule = true
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.title2)
                        .foregroundColor(.accentBlue)
                }
            }
            
            Text(viewModel.module.moduleDescription)
                .font(.subheadline)
                .foregroundColor(.dashboardTextSecondary)
        }
        .padding()
        .background(Color.dashboardCard)
        .cornerRadius(20)
    }
    
    // MARK: - Lessons Section
    private var lessonsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Lessons")
                    .font(.headline)
                    .foregroundColor(.dashboardTextSecondary)
                
                Spacer()
                
                Button {
                    showAddLesson = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentBlue)
                }
            }
            
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(.accentBlue)
                    Spacer()
                }
                .padding(.vertical, 40)
            } else if viewModel.lessons.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "list.bullet.clipboard")
                        .font(.system(size: 40))
                        .foregroundColor(.dashboardTextSecondary)
                    Text("No lessons yet")
                        .font(.headline)
                        .foregroundColor(.dashboardTextPrimary)
                    Button("Add First Lesson") {
                        showAddLesson = true
                    }
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.accentBlue)
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color.dashboardCard)
                .cornerRadius(16)
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.lessons) { lesson in
                        NavigationLink(destination: ContentManagementView(lesson: lesson, courseId: viewModel.courseId)) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(lesson.title)
                                        .font(.headline)
                                        .foregroundColor(.dashboardTextPrimary)
                                    Text(lesson.lessonDescription)
                                        .font(.subheadline)
                                        .foregroundColor(.dashboardTextSecondary)
                                        .lineLimit(2)
                                    
                                    if let objectives = lesson.learningObjectives {
                                        Text("Objectives: \(objectives)")
                                            .font(.caption)
                                            .foregroundColor(.accentBlue)
                                            .lineLimit(1)
                                            .padding(.top, 2)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.dashboardTextSecondary)
                            }
                            .padding()
                            .background(Color.dashboardCard)
                            .cornerRadius(16)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Add Lesson View
struct AddLessonView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ModuleLessonViewModel
    
    @State private var title = ""
    @State private var description = ""
    @State private var objectives = ""
    @State private var prerequisites = ""
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            Color.dashboardBg.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.dashboardTextSecondary)
                    Spacer()
                    Text("Add Lesson")
                        .font(.headline)
                        .foregroundColor(.dashboardTextPrimary)
                    Spacer()
                    Button("Add") {
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
                    .fontWeight(.bold)
                    .foregroundColor(.accentBlue)
                    .disabled(title.isEmpty || description.isEmpty || isLoading)
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Lesson Information")
                                .font(.headline)
                                .foregroundColor(.dashboardTextSecondary)
                            
                            customTextField(title: "Lesson Title", text: $title)
                            customTextField(title: "Description", text: $description, isMultiline: true)
                        }
                        .padding()
                        .background(Color.dashboardCard)
                        .cornerRadius(20)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Learning Details")
                                .font(.headline)
                                .foregroundColor(.dashboardTextSecondary)
                            
                            customTextField(title: "Learning Objectives (Optional)", text: $objectives, isMultiline: true)
                            customTextField(title: "Prerequisites (Optional)", text: $prerequisites, isMultiline: true)
                        }
                        .padding()
                        .background(Color.dashboardCard)
                        .cornerRadius(20)
                    }
                    .padding()
                }
            }
        }
    }
    
    @ViewBuilder
    private func customTextField(title: String, text: Binding<String>, isMultiline: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.dashboardTextSecondary)
            
            if isMultiline {
                TextEditor(text: text)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: isMultiline ? 80 : 0)
                    .padding(12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .foregroundColor(.dashboardTextPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            } else {
                TextField(title, text: text)
                    .padding(12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .foregroundColor(.dashboardTextPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            }
        }
    }
}

#Preview {
    ModuleLessonEditorView(
        module: Module(
            id: "1",
            courseId: "course1",
            title: "Introduction to SwiftUI",
            moduleDescription: "Learn the basics of SwiftUI",
            orderIndex: 0,
            createdAt: Date(),
            updatedAt: Date()
        ),
        courseId: "course1"
    )
}
