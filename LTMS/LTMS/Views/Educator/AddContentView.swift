//
//  AddContentView.swift
//  LTMS
//
//  Created for Content Upload
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import Combine

@MainActor
class AddContentViewModel: ObservableObject {
    @Published var title = ""
    @Published var selectedType: ContentType = .pdf
    @Published var textContent = ""
    @Published var selectedFileData: Data?
    @Published var selectedFileName: String?
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    @Published var errorMessage: String?
    @Published var showError = false
    
    let lesson: Lesson
    let courseId: String
    
    init(lesson: Lesson, courseId: String) {
        self.lesson = lesson
        self.courseId = courseId
    }
    
    var canSave: Bool {
        !title.isEmpty && (selectedFileData != nil || selectedType == .text && !textContent.isEmpty)
    }
    
    func saveContent() async throws -> Bool {
        guard let lessonId = lesson.id else { return false }
        
        isUploading = true
        defer { isUploading = false }
        
        var fileURL: String? = nil
        
        // Upload file if not text content
        if selectedType != .text, let data = selectedFileData {
            let fileName = selectedFileName ?? "\(UUID().uuidString).\(selectedType.fileExtension)"
            
            do {
                switch selectedType {
                case .video:
                    fileURL = try await ContentService.shared.uploadVideo(
                        data: data,
                        organizationId: AppConstants.defaultOrganizationId,
                        courseId: courseId,
                        fileName: fileName
                    )
                case .pdf:
                    fileURL = try await ContentService.shared.uploadPDF(
                        data: data,
                        organizationId: AppConstants.defaultOrganizationId,
                        courseId: courseId,
                        fileName: fileName
                    )
                case .slide:
                    fileURL = try await ContentService.shared.uploadSlide(
                        data: data,
                        organizationId: AppConstants.defaultOrganizationId,
                        courseId: courseId,
                        fileName: fileName
                    )
                case .text:
                    break
                }
            } catch {
                errorMessage = "Upload failed: \(error.localizedDescription)"
                showError = true
                return false
            }
        }
        
        // Create content record
        let content = Content(
            id: nil,
            lessonId: lessonId,
            contentType: selectedType,
            title: title,
            fileURL: fileURL,
            textContent: selectedType == .text ? textContent : nil,
            metadata: nil,
            version: 1,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        do {
            _ = try await ContentService.shared.createContent(content)
            return true
        } catch {
            errorMessage = "Failed to save content: \(error.localizedDescription)"
            showError = true
            return false
        }
    }
}

struct AddContentView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AddContentViewModel
    @State private var showDocumentPicker = false
    @State private var showVideoPicker = false
    @State private var selectedVideoItem: PhotosPickerItem?
    
    let onContentAdded: () -> Void
    
    init(lesson: Lesson, courseId: String, onContentAdded: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: AddContentViewModel(lesson: lesson, courseId: courseId))
        self.onContentAdded = onContentAdded
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Content Type Selection
                Section("Content Type") {
                    Picker("Type", selection: $viewModel.selectedType) {
                        ForEach(ContentType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: viewModel.selectedType) { _, _ in
                        viewModel.selectedFileData = nil
                        viewModel.selectedFileName = nil
                    }
                }
                
                // Basic Info
                Section("Details") {
                    TextField("Content Title", text: $viewModel.title)
                        .autocorrectionDisabled()
                }
                
                // Content Input Based on Type
                if viewModel.selectedType == .text {
                    Section("Text Content") {
                        TextEditor(text: $viewModel.textContent)
                            .frame(minHeight: 200)
                    }
                } else {
                    Section("File") {
                        if let fileName = viewModel.selectedFileName {
                            HStack {
                                Image(systemName: viewModel.selectedType.icon)
                                    .foregroundColor(viewModel.selectedType.color)
                                Text(fileName)
                                    .font(.subheadline)
                                Spacer()
                                Button("Change") {
                                    if viewModel.selectedType == .video {
                                        showVideoPicker = true
                                    } else {
                                        showDocumentPicker = true
                                    }
                                }
                                .font(.caption)
                            }
                        } else {
                            Button {
                                if viewModel.selectedType == .video {
                                    showVideoPicker = true
                                } else {
                                    showDocumentPicker = true
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.up.doc")
                                    Text("Choose \(viewModel.selectedType.displayName) File")
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                
                // Upload Progress
                if viewModel.isUploading {
                    Section {
                        VStack(spacing: 8) {
                            ProgressView(value: viewModel.uploadProgress)
                            Text("Uploading... \(Int(viewModel.uploadProgress * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Save Button
                Section {
                    Button(viewModel.isUploading ? "Uploading..." : "Add Content") {
                        Task {
                            do {
                                if try await viewModel.saveContent() {
                                    onContentAdded()
                                    dismiss()
                                }
                            } catch {
                                print("Error saving content: \(error)")
                            }
                        }
                    }
                    .disabled(!viewModel.canSave || viewModel.isUploading)
                }
            }
            .navigationTitle("Add Content")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(viewModel.isUploading)
                }
            }
            .fileImporter(
                isPresented: $showDocumentPicker,
                allowedContentTypes: allowedFileTypes,
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
            .photosPicker(
                isPresented: $showVideoPicker,
                selection: $selectedVideoItem,
                matching: .videos
            )
            .onChange(of: selectedVideoItem) { _, newItem in
                Task {
                    await loadVideoData(from: newItem)
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
        }
    }
    
    private var allowedFileTypes: [UTType] {
        switch viewModel.selectedType {
        case .pdf:
            return [.pdf]
        case .slide:
            return [.pdf, .presentation]
        case .video:
            return [.movie, .video, .mpeg4Movie]
        case .text:
            return [.text]
        }
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            // Start accessing security-scoped resource
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            
            do {
                let data = try Data(contentsOf: url)
                viewModel.selectedFileData = data
                viewModel.selectedFileName = url.lastPathComponent
            } catch {
                viewModel.errorMessage = "Failed to read file: \(error.localizedDescription)"
                viewModel.showError = true
            }
            
        case .failure(let error):
            viewModel.errorMessage = "File selection failed: \(error.localizedDescription)"
            viewModel.showError = true
        }
    }
    
    private func loadVideoData(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        do {
            if let movie = try await item.loadTransferable(type: VideoTransferable.self) {
                viewModel.selectedFileData = movie.data
                viewModel.selectedFileName = "video.mp4"
            }
        } catch {
            viewModel.errorMessage = "Failed to load video: \(error.localizedDescription)"
            viewModel.showError = true
        }
    }
}

// MARK: - Video Transferable

struct VideoTransferable: Transferable {
    let data: Data
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .movie) { data in
            VideoTransferable(data: data)
        }
    }
}

// MARK: - ContentType Extension

extension ContentType {
    var fileExtension: String {
        switch self {
        case .video:
            return "mp4"
        case .pdf:
            return "pdf"
        case .slide:
            return "pdf"
        case .text:
            return "txt"
        }
    }
}
