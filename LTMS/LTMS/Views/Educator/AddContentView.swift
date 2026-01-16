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
            ZStack {
                Color.dashboardBg.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button("Cancel") { dismiss() }
                            .foregroundColor(.dashboardTextSecondary)
                        Spacer()
                        Text("Add Content")
                            .font(.headline)
                            .foregroundColor(.dashboardTextPrimary)
                        Spacer()
                        Button("Cancel") { }
                            .opacity(0)
                    }
                    .padding()
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            
                            // Content Type Selection
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Content Type")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.dashboardTextSecondary)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(ContentType.allCases, id: \.self) { type in
                                            Button(action: {
                                                withAnimation {
                                                    viewModel.selectedType = type
                                                }
                                            }) {
                                                VStack(spacing: 8) {
                                                    ZStack {
                                                        Circle()
                                                            .fill(viewModel.selectedType == type ? type.color.opacity(0.2) : Color.white.opacity(0.05))
                                                            .frame(width: 50, height: 50)
                                                        
                                                        Image(systemName: type.icon)
                                                            .font(.title2)
                                                            .foregroundColor(viewModel.selectedType == type ? type.color : .dashboardTextSecondary)
                                                    }
                                                    
                                                    Text(type.displayName)
                                                        .font(.caption)
                                                        .fontWeight(viewModel.selectedType == type ? .bold : .regular)
                                                        .foregroundColor(viewModel.selectedType == type ? .dashboardTextPrimary : .dashboardTextSecondary)
                                                }
                                                .padding(.vertical, 8)
                                                .padding(.horizontal, 12)
                                                .background(viewModel.selectedType == type ? Color.dashboardCard : Color.clear)
                                                .cornerRadius(16)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .stroke(viewModel.selectedType == type ? type.color.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                                                )
                                            }
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color.dashboardCard)
                            .cornerRadius(20)
                            
                            // Basic Info
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Details")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.dashboardTextSecondary)
                                
                                customTextField(title: "Content Title", text: $viewModel.title)
                            }
                            .padding()
                            .background(Color.dashboardCard)
                            .cornerRadius(20)
                            
                            // Content Input
                            VStack(alignment: .leading, spacing: 16) {
                                if viewModel.selectedType == .text {
                                    Text("Text Content")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.dashboardTextSecondary)
                                    
                                    customTextField(title: "Content", text: $viewModel.textContent, isMultiline: true)
                                } else {
                                    Text("File Upload")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.dashboardTextSecondary)
                                    
                                    if let fileName = viewModel.selectedFileName {
                                        HStack {
                                            Image(systemName: viewModel.selectedType.icon)
                                                .foregroundColor(viewModel.selectedType.color)
                                                .font(.title3)
                                            Text(fileName)
                                                .font(.subheadline)
                                                .foregroundColor(.dashboardTextPrimary)
                                            Spacer()
                                            Button("Change") {
                                                if viewModel.selectedType == .video {
                                                    showVideoPicker = true
                                                } else {
                                                    showDocumentPicker = true
                                                }
                                            }
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.accentBlue)
                                        }
                                        .padding()
                                        .background(Color.white.opacity(0.05))
                                        .cornerRadius(12)
                                    } else {
                                        Button {
                                            if viewModel.selectedType == .video {
                                                showVideoPicker = true
                                            } else {
                                                showDocumentPicker = true
                                            }
                                        } label: {
                                            VStack(spacing: 12) {
                                                Image(systemName: "arrow.up.doc")
                                                    .font(.largeTitle)
                                                    .foregroundColor(.accentBlue)
                                                Text("Choose \(viewModel.selectedType.displayName) File")
                                                    .font(.headline)
                                                    .foregroundColor(.dashboardTextSecondary)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 32)
                                            .background(Color.white.opacity(0.05))
                                            .cornerRadius(16)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                                    .foregroundColor(.accentBlue.opacity(0.5))
                                            )
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color.dashboardCard)
                            .cornerRadius(20)
                            
                            // Upload Progress
                            if viewModel.isUploading {
                                VStack(spacing: 8) {
                                    ProgressView(value: viewModel.uploadProgress)
                                        .tint(.accentBlue)
                                    Text("Uploading... \(Int(viewModel.uploadProgress * 100))%")
                                        .font(.caption)
                                        .foregroundColor(.dashboardTextSecondary)
                                }
                                .padding()
                                .background(Color.dashboardCard)
                                .cornerRadius(16)
                            }
                            
                            // Save Button
                            Button(action: {
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
                            }) {
                                ZStack {
                                    if viewModel.isUploading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("Add Content")
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
                            .disabled(!viewModel.canSave || viewModel.isUploading)
                            .opacity(!viewModel.canSave || viewModel.isUploading ? 0.6 : 1.0)
                        }
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
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

