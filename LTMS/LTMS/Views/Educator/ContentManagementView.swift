//
//  ContentManagementView.swift
//  LTMS
//
//  Created for Content Management
//

import SwiftUI
import Combine
import PhotosUI
import UniformTypeIdentifiers

@MainActor
class ContentManagementViewModel: ObservableObject {
    @Published var contents: [Content] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var lesson: Lesson
    
    let courseId: String
    
    init(lesson: Lesson, courseId: String) {
        self.lesson = lesson
        self.courseId = courseId
    }
    
    func loadContents() async {
        guard let lessonId = lesson.id else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            contents = try await ContentService.shared.fetchContentsByLesson(lessonId: lessonId)
            print("✅ Loaded \(contents.count) contents for lesson")
        } catch {
            print("❌ Error loading contents: \(error)")
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func deleteContent(_ content: Content) async {
        guard let id = content.id else { return }
        
        do {
            try await ContentService.shared.deleteContent(id: id)
            await loadContents()
        } catch {
            errorMessage = "Failed to delete content: \(error.localizedDescription)"
            showError = true
        }
    }
    
    func updateLesson(title: String, description: String, objectives: String?, prerequisites: String?) async throws {
        guard let lessonId = lesson.id else { return }
        
        var updatedLesson = lesson
        updatedLesson.title = title
        updatedLesson.lessonDescription = description
        updatedLesson.learningObjectives = objectives
        updatedLesson.prerequisites = prerequisites
        updatedLesson.updatedAt = Date()
        
        try await CourseService.shared.updateLesson(updatedLesson)
        self.lesson = updatedLesson
    }
    
    func updateContent(_ content: Content, title: String, textContent: String?) async throws {
        var updatedContent = content
        updatedContent.title = title
        updatedContent.textContent = textContent
        updatedContent.updatedAt = Date()
        
        try await ContentService.shared.updateContent(updatedContent)
        await loadContents()
    }
}

struct ContentManagementView: View {
    @StateObject private var viewModel: ContentManagementViewModel
    @State private var showAddContent = false
    @State private var showEditLesson = false
    
    init(lesson: Lesson, courseId: String) {
        _viewModel = StateObject(wrappedValue: ContentManagementViewModel(lesson: lesson, courseId: courseId))
    }
    
    var body: some View {
        List {
            // Lesson Info Section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(viewModel.lesson.title)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button {
                            showEditLesson = true
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .font(.title2)
                                .foregroundColor(.ltmsPrimary)
                        }
                    }
                    
                    Text(viewModel.lesson.lessonDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let objectives = viewModel.lesson.learningObjectives {
                        Label(objectives, systemImage: "target")
                            .font(.caption)
                            .foregroundColor(.ltmsPrimary)
                    }
                }
                .padding(.vertical, 4)
            }
            
            // Quizzes Section - Navigate to QuizListView for this lesson
            Section {
                NavigationLink(destination: QuizListView(
                    course: Course(
                        id: viewModel.courseId,
                        organizationId: "",
                        title: "",
                        courseDescription: "",
                        level: .beginner,
                        durationHours: 0,
                        isPublished: false,
                        createdById: "",
                        createdAt: Date(),
                        updatedAt: Date(),
                        isVisibleInCatalog: false
                    ),
                    lesson: viewModel.lesson
                )) {
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.purple)
                            .frame(width: 40)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Quizzes")
                                .font(.headline)
                            Text("Create and manage quizzes for this lesson")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
//                        
//                        Image(systemName: "chevron.right")
//                            .font(.caption)
//                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // Content List Section
            Section {
                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if viewModel.contents.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No content added yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Add videos, PDFs, slides, or text content")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Add Content") {
                            showAddContent = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                } else {
                    ForEach(viewModel.contents) { content in
                        ContentRow(content: content, viewModel: viewModel)
                    }
                }
            } header: {
                HStack {
                    Text("Learning Materials (\(viewModel.contents.count))")
                    Spacer()
                    if !viewModel.contents.isEmpty {
                        Button {
                            showAddContent = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                }
            }
        }
        .navigationTitle("Lesson Content")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddContent) {
            AddContentView(
                lesson: viewModel.lesson,
                courseId: viewModel.courseId,
                onContentAdded: {
                    Task {
                        await viewModel.loadContents()
                    }
                }
            )
        }
        .sheet(isPresented: $showEditLesson) {
            ContentEditLessonView(viewModel: viewModel)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .task {
            await viewModel.loadContents()
        }
    }
}

struct ContentRow: View {
    let content: Content
    @ObservedObject var viewModel: ContentManagementViewModel
    @State private var showDeleteAlert = false
    @State private var showTextContent = false
    @State private var showEditContent = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Content Type Icon
            ZStack {
                Circle()
                    .fill(content.contentType.color.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: content.contentType.icon)
                    .foregroundColor(content.contentType.color)
                    .font(.title3)
            }
            
            // Content Info
            VStack(alignment: .leading, spacing: 4) {
                Text(content.title)
                    .font(.headline)
                
                Text(content.contentType.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if content.fileURL != nil {
                    Label("File attached", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                } else if content.textContent != nil {
                    Label("Text content", systemImage: "checkmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            // Actions Menu
            Menu {
                // Preview for file-based content
                if let url = content.fileURL, let fileURL = URL(string: url) {
                    Button {
                        UIApplication.shared.open(fileURL)
                    } label: {
                        Label("Preview", systemImage: "eye")
                    }
                }
                
                // View for text content
                if content.textContent != nil {
                    Button {
                        showTextContent = true
                    } label: {
                        Label("View Content", systemImage: "eye")
                    }
                }
                
                // Edit option
                Button {
                    showEditContent = true
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
        .padding(.vertical, 4)
        .alert("Delete Content?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteContent(content)
                }
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .sheet(isPresented: $showTextContent) {
            TextContentViewerSheet(content: content)
        }
        .sheet(isPresented: $showEditContent) {
            EditContentView(viewModel: viewModel, content: content)
        }
    }
}

// MARK: - Text Content Viewer

struct TextContentViewerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let content: Content
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(content.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Divider()
                    
                    if let textContent = content.textContent {
                        Text(textContent)
                            .font(.body)
                    } else {
                        Text("No content available")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Text Content")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Edit Content View

struct EditContentView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ContentManagementViewModel
    let content: Content
    
    @State private var title: String
    @State private var textContent: String
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    init(viewModel: ContentManagementViewModel, content: Content) {
        self.viewModel = viewModel
        self.content = content
        _title = State(initialValue: content.title)
        _textContent = State(initialValue: content.textContent ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Content Title") {
                    TextField("Title", text: $title)
                }
                
                if content.contentType == .text {
                    Section("Text Content") {
                        TextField("Content", text: $textContent, axis: .vertical)
                            .lineLimit(5...15)
                    }
                }
                
                if content.fileURL != nil {
                    Section("File") {
                        HStack {
                            Image(systemName: content.contentType.icon)
                                .foregroundColor(content.contentType.color)
                            Text("File attached")
                                .foregroundColor(.secondary)
                        }
                        Text("To change the file, delete this content and create a new one.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button("Save Changes") {
                        Task {
                            isLoading = true
                            defer { isLoading = false }
                            do {
                                try await viewModel.updateContent(
                                    content,
                                    title: title,
                                    textContent: content.contentType == .text ? (textContent.isEmpty ? nil : textContent) : content.textContent
                                )
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                showError = true
                            }
                        }
                    }
                    .disabled(title.isEmpty || isLoading)
                }
            }
            .navigationTitle("Edit Content")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "Failed to update content")
            }
        }
    }
}

// MARK: - Edit Lesson View for Content Management

struct ContentEditLessonView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ContentManagementViewModel
    
    @State private var title: String
    @State private var description: String
    @State private var objectives: String
    @State private var prerequisites: String
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    init(viewModel: ContentManagementViewModel) {
        self.viewModel = viewModel
        _title = State(initialValue: viewModel.lesson.title)
        _description = State(initialValue: viewModel.lesson.lessonDescription)
        _objectives = State(initialValue: viewModel.lesson.learningObjectives ?? "")
        _prerequisites = State(initialValue: viewModel.lesson.prerequisites ?? "")
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

// MARK: - Content Type Extensions

extension ContentType {
    var color: Color {
        switch self {
        case .video:
            return .purple
        case .pdf:
            return .red
        case .slide:
            return .orange
        case .text:
            return .blue
        }
    }
}

#Preview {
    NavigationStack {
        ContentManagementView(
            lesson: Lesson(
                id: "1",
                moduleId: "module1",
                title: "Introduction to SwiftUI",
                lessonDescription: "Learn the basics",
                orderIndex: 0,
                learningObjectives: "Master SwiftUI fundamentals",
                prerequisites: nil,
                createdAt: Date(),
                updatedAt: Date()
            ),
            courseId: "course1"
        )
    }
}
