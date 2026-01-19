

import SwiftUI
import PDFKit
import AVKit
import WebKit

struct ContentPlayerView: View {
    let content: Content
    let courseId: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Content Header
                contentHeader
                
                // Content Player
                contentPlayer
            }
            .padding()
        }
        .background(Color.dashboardBg)
        .navigationTitle(content.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.dashboardBg, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
    
    // MARK: - Content Header
    
    private var contentHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(content.contentType.color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: content.contentType.icon)
                        .font(.title2)
                        .foregroundStyle(content.contentType.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(content.contentType.displayName)
                        .font(.caption)
                        .fontWeight(.bold)
                        .textCase(.uppercase)
                        .foregroundColor(content.contentType.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(content.contentType.color.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            
            Text(content.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.dashboardTextPrimary)
                .lineLimit(2)
        }
        .padding(20)
        .background(Color.dashboardCard)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Content Player
    
    @ViewBuilder
    private var contentPlayer: some View {
        switch content.contentType {
        case .video:
            if let urlString = content.fileURL, let url = URL(string: urlString) {
                VideoPlayerView(url: url)
            } else {
                errorView("Video not available")
            }
            
        case .pdf, .slide:
            if let urlString = content.fileURL, let url = URL(string: urlString) {
                PDFViewerView(url: url)
            } else {
                errorView("PDF not available")
            }
            
        case .text:
            if let textContent = content.textContent {
                TextContentView(text: textContent)
            } else {
                errorView("Content not available")
            }
        }
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
        .background(Color.dashboardCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Video Player View

struct VideoPlayerView: View {
    let url: URL
    @State private var player: AVPlayer?
    
    var body: some View {
        VStack(spacing: 0) {
            if let player = player {
                VideoPlayer(player: player)
                    .frame(height: 250)
                    .cornerRadius(12)
            } else {
                Rectangle()
                    .fill(Color.black)
                    .frame(height: 250)
                    .overlay(
                        ProgressView()
                            .tint(.white)
                    )
                    .cornerRadius(12)
            }
            
            // Video Controls Info
            VStack(alignment: .leading, spacing: 12) {
                Label("Video Content", systemImage: "play.circle.fill")
                    .font(.headline)
                    .foregroundColor(.purple)
                
                Text("Tap play to start watching. You can pause, seek, and control playback using the video controls.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.purple.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.purple.opacity(0.2), lineWidth: 1)
            )
            .padding(.top)
        }
        .onAppear {
            player = AVPlayer(url: url)
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
}

// MARK: - PDF Viewer View

struct PDFViewerView: View {
    let url: URL
    @State private var pdfDocument: PDFDocument?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 16) {
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading PDF...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(height: 400)
            } else if let error = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.fill.badge.exclamationmark")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 400)
            } else if let document = pdfDocument {
                PDFKitRepresentedView(document: document)
                    .frame(minHeight: 500)
                    .cornerRadius(12)
                
                // PDF Info
                VStack(alignment: .leading, spacing: 12) {
                    Label("PDF Document", systemImage: "doc.text.fill")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    if document.pageCount > 0 {
                        Text("\(document.pageCount) pages")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Swipe or pinch to zoom and navigate through the document.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.red.opacity(0.2), lineWidth: 1)
                )
            }
        }
        .task {
            await loadPDF()
        }
    }
    
    private func loadPDF() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            if let document = PDFDocument(data: data) {
                self.pdfDocument = document
                self.errorMessage = nil
            } else {
                self.errorMessage = "Failed to load PDF document"
            }
        } catch {
            self.errorMessage = "Error loading PDF: \(error.localizedDescription)"
        }
    }
}

// MARK: - PDFKit Wrapper

struct PDFKitRepresentedView: UIViewRepresentable {
    let document: PDFDocument
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = document
    }
}

// MARK: - Text Content View

struct TextContentView: View {
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Text Content Card
            VStack(alignment: .leading, spacing: 16) {
                Text(text)
                    .font(.body)
                    .foregroundColor(.dashboardTextPrimary)
                    .lineSpacing(8)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.dashboardCard)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            
            // Text Info
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 44, height: 44)
                    Image(systemName: "book.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 20))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reading Material")
                        .font(.headline)
                        .foregroundColor(.dashboardTextPrimary)
                    
                    Text("Read at your own pace")
                        .font(.caption)
                        .foregroundColor(.dashboardTextSecondary)
                }
                
                Spacer()
            }
            .padding(20)
            .background(Color.dashboardCard)
            .cornerRadius(20)
        }
    }
}

#Preview {
    NavigationStack {
        ContentPlayerView(
            content: Content(
                id: "1",
                lessonId: "lesson1",
                contentType: .text,
                title: "Introduction to SwiftUI",
                fileURL: nil,
                textContent: "SwiftUI is a modern way to build user interfaces for Apple platforms. It uses a declarative syntax that makes it easy to create complex UIs with minimal code.",
                metadata: nil,
                version: 1,
                createdAt: Date(),
                updatedAt: Date()
            ),
            courseId: "course1"
        )
    }
}
