

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
        guard lesson.id != nil else { return }
        
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
    @Environment(\.dismiss) private var dismiss
    @State private var showAddContent = false
    @State private var showEditLesson = false
    
    init(lesson: Lesson, courseId: String) {
        _viewModel = StateObject(wrappedValue: ContentManagementViewModel(lesson: lesson, courseId: courseId))
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
                        
                        Text("Lesson Content")
                            .font(.headline)
                            .foregroundColor(.dashboardTextPrimary)
                        
                        Spacer()
                        
                        // Invisible spacer for balance
                        Color.clear.frame(width: 40, height: 40)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Lesson Info Card
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(viewModel.lesson.title)
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.dashboardTextPrimary)
                                    
                                    Spacer()
                                    
                                    Button {
                                        showEditLesson = true
                                    } label: {
                                        Image(systemName: "square.and.pencil")
                                            .font(.title2)
                                            .foregroundColor(.accentBlue)
                                    }
                                }
                                
                                Text(viewModel.lesson.lessonDescription)
                                    .font(.subheadline)
                                    .foregroundColor(.dashboardTextSecondary)
                                
                                if let objectives = viewModel.lesson.learningObjectives {
                                    HStack {
                                        Image(systemName: "target")
                                            .foregroundColor(.accentBlue)
                                        Text(objectives)
                                            .font(.caption)
                                            .foregroundColor(.accentBlue)
                                    }
                                    .padding(.top, 4)
                                }
                            }
                            .padding()
                            .background(Color.dashboardCard)
                            .cornerRadius(20)
                            
                            // Quizzes Card
                            NavigationLink(destination: QuizListView(
                                course: Course(
                                    id: viewModel.courseId,
                                    organizationId: "",
                                    title: "",
                                    courseDescription: "",
                                    level: .beginner,
                                    durationHours: 0,
                                    thumbnailURL: nil,
                                    isPublished: false,
                                    createdById: "",
                                    assignedEducatorId: nil,
                                    createdAt: Date(),
                                    updatedAt: Date(),
                                    isVisibleInCatalog: false
                                ),
                                lesson: viewModel.lesson
                            )) {
                                HStack {
                                    Image(systemName: "questionmark.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.accentPurple)
                                        .frame(width: 40)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Quizzes")
                                            .font(.headline)
                                            .foregroundColor(.dashboardTextPrimary)
                                        Text("Create and manage quizzes for this lesson")
                                            .font(.caption)
                                            .foregroundColor(.dashboardTextSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.dashboardTextSecondary)
                                }
                                .padding()
                                .background(Color.dashboardCard)
                                .cornerRadius(20)
                            }
                            .buttonStyle(.plain)
                            
                            // Content List Section
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Learning Materials (\(viewModel.contents.count))")
                                        .font(.headline)
                                        .foregroundColor(.dashboardTextSecondary)
                                    Spacer()
                                    Button {
                                        showAddContent = true
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
                                    .padding(.vertical, 20)
                                } else if viewModel.contents.isEmpty {
                                    VStack(spacing: 16) {
                                        Image(systemName: "doc.text.magnifyingglass")
                                            .font(.system(size: 40))
                                            .foregroundColor(.dashboardTextSecondary)
                                        Text("No content added yet")
                                            .font(.headline)
                                            .foregroundColor(.dashboardTextPrimary)
                                        Text("Add videos, PDFs, slides, or text content")
                                            .font(.caption)
                                            .foregroundColor(.dashboardTextSecondary)
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                                    .background(Color.dashboardCard)
                                    .cornerRadius(16)
                                } else {
                                    VStack(spacing: 12) {
                                        ForEach(viewModel.contents) { content in
                                            ContentRow(content: content, viewModel: viewModel)
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
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
                // Use dashboard colors instead of content.contentType.color manually for better theme integration if desired,
                // but keeping original functionality with opacity is fine, just ensuring it looks good on dark bg.
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
                    .foregroundColor(.dashboardTextPrimary)
                
                Text(content.contentType.displayName)
                    .font(.caption)
                    .foregroundColor(.dashboardTextSecondary)
                
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
                
                Button {
                    showEditContent = true
                } label: {
                    Label("Edit", systemImage: "square.and.pencil")
                }
                
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundColor(.dashboardTextSecondary)
            }
        }
        .padding()
        .background(Color.dashboardCard)
        .cornerRadius(16)
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
            ZStack {
                Color.dashboardBg.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Text("Text Content")
                            .font(.headline)
                            .foregroundColor(.dashboardTextPrimary)
                        Spacer()
                        Button("Done") { dismiss() }
                            .fontWeight(.bold)
                            .foregroundColor(.accentBlue)
                    }
                    .padding()
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(content.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.dashboardTextPrimary)
                            
                            Divider()
                                .background(Color.dashboardTextSecondary.opacity(0.3))
                            
                            if let textContent = content.textContent {
                                Text(textContent)
                                    .font(.body)
                                    .foregroundColor(.dashboardTextSecondary)
                            } else {
                                Text("No content available")
                                    .font(.body)
                                    .foregroundColor(.dashboardTextSecondary)
                            }
                        }
                        .padding()
                        .background(Color.dashboardCard)
                        .cornerRadius(20)
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
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
            ZStack {
                Color.dashboardBg.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button("Cancel") { dismiss() }
                            .foregroundColor(.dashboardTextSecondary)
                        Spacer()
                        Text("Edit Content")
                            .font(.headline)
                            .foregroundColor(.dashboardTextPrimary)
                        Spacer()
                        Button("Cancel") { }
                            .opacity(0)
                    }
                    .padding()
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 16) {
                                customTextField(title: "Title", text: $title)
                                
                                if content.contentType == .text {
                                    customTextField(title: "Content", text: $textContent, isMultiline: true)
                                }
                                
                                if content.fileURL != nil {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("File")
                                            .font(.caption)
                                            .foregroundColor(.dashboardTextSecondary)
                                        
                                        HStack {
                                            Image(systemName: content.contentType.icon)
                                                .foregroundColor(content.contentType.color)
                                            Text("File attached")
                                                .foregroundColor(.dashboardTextPrimary)
                                        }
                                        .padding(12)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(12)
                                        
                                        Text("To change the file, delete this content and create a new one.")
                                            .font(.caption)
                                            .foregroundColor(.dashboardTextSecondary)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.dashboardCard)
                            .cornerRadius(20)
                            
                            // Save Button
                            Button(action: saveChanges) {
                                ZStack {
                                    if isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("Save Changes")
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
                            .disabled(title.isEmpty || isLoading)
                            .opacity(title.isEmpty || isLoading ? 0.6 : 1.0)
                        }
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "Failed to update content")
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
                    .frame(minHeight: 150)
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
    
    private func saveChanges() {
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
            ZStack {
                Color.dashboardBg.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button("Cancel") { dismiss() }
                            .foregroundColor(.dashboardTextSecondary)
                        Spacer()
                        Text("Edit Lesson")
                            .font(.headline)
                            .foregroundColor(.dashboardTextPrimary)
                        Spacer()
                        Button("Cancel") { }
                            .opacity(0)
                    }
                    .padding()
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Lesson Information
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Lesson Information")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.dashboardTextSecondary)
                                
                                customTextField(title: "Lesson Title", text: $title)
                                customTextField(title: "Description", text: $description, isMultiline: true)
                            }
                            .padding()
                            .background(Color.dashboardCard)
                            .cornerRadius(20)
                            
                            // Learning Details
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Learning Details")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.dashboardTextSecondary)
                                
                                customTextField(title: "Learning Objectives (Optional)", text: $objectives, isMultiline: true)
                                customTextField(title: "Prerequisites (Optional)", text: $prerequisites, isMultiline: true)
                            }
                            .padding()
                            .background(Color.dashboardCard)
                            .cornerRadius(20)
                            
                            // Save Button
                            Button(action: saveChanges) {
                                ZStack {
                                    if isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("Save Changes")
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
                            .disabled(title.isEmpty || description.isEmpty || isLoading)
                            .opacity(title.isEmpty || description.isEmpty || isLoading ? 0.6 : 1.0)
                        }
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "Failed to update lesson")
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
                    .frame(minHeight: 100)
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
    
    private func saveChanges() {
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
