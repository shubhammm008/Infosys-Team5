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
    
    let lesson: Lesson
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
}

struct ContentManagementView: View {
    @StateObject private var viewModel: ContentManagementViewModel
    @State private var showAddContent = false
    
    init(lesson: Lesson, courseId: String) {
        _viewModel = StateObject(wrappedValue: ContentManagementViewModel(lesson: lesson, courseId: courseId))
    }
    
    var body: some View {
        List {
            // Lesson Info Section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.lesson.title)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
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
                }
            }
            
            Spacer()
            
            // Actions Menu
            Menu {
                if let url = content.fileURL, let fileURL = URL(string: url) {
                    Button {
                        UIApplication.shared.open(fileURL)
                    } label: {
                        Label("Preview", systemImage: "eye")
                    }
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
