

import SwiftUI
import Combine

@MainActor
class LessonViewerViewModel: ObservableObject {
    @Published var contents: [Content] = []
    @Published var quizzes: [Quiz] = []
    @Published var quizSubmissions: [String: QuizSubmission] = [:]  // quizId -> submission
    @Published var currentProgress: Progress?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    let lesson: Lesson
    let courseId: String
    let enrollmentId: String?
    private var userId: String? { SupabaseAuthService.shared.currentUser?.id }
    
    init(lesson: Lesson, courseId: String, enrollmentId: String?) {
        self.lesson = lesson
        self.courseId = courseId
        self.enrollmentId = enrollmentId
    }
    
    func loadLessonContent() async {
        guard let lessonId = lesson.id else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Load contents
            contents = try await ContentService.shared.fetchContentsByLesson(lessonId: lessonId)
            
            // Load progress
            if let enrollmentId = enrollmentId {
                currentProgress = try await ContentService.shared.fetchProgressByLesson(
                    enrollmentId: enrollmentId,
                    lessonId: lessonId
                )
            }
            
            // Load quizzes for this lesson
            quizzes = try await QuizService.shared.fetchQuizzesByLesson(lessonId: lessonId)
            print("✅ Loaded \(quizzes.count) quizzes for lesson")
            
            // Load user's quiz submissions
            if let userId = userId {
                let allSubmissions = try await QuizService.shared.fetchSubmissionsByUser(userId: userId)
                for submission in allSubmissions {
                    quizSubmissions[submission.assessmentId] = submission
                }
                print("✅ Loaded \(quizSubmissions.count) quiz submissions")
            }
            
            print("✅ Loaded \(contents.count) contents for lesson")
        } catch {
            print("❌ Error loading lesson content: \(error)")
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func markLessonComplete() async {
        guard let lessonId = lesson.id,
              let enrollmentId = enrollmentId else { return }
        
        do {
            try await ContentService.shared.markLessonComplete(
                enrollmentId: enrollmentId,
                lessonId: lessonId
            )
            
            // Reload progress
            currentProgress = try await ContentService.shared.fetchProgressByLesson(
                enrollmentId: enrollmentId,
                lessonId: lessonId
            )
        } catch {
            errorMessage = "Failed to mark lesson complete: \(error.localizedDescription)"
            showError = true
        }
    }
}

struct LessonViewerView: View {
    @StateObject private var viewModel: LessonViewerViewModel
    @State private var showCompleteConfirmation = false
    
    init(lesson: Lesson, courseId: String, enrollmentId: String?) {
        _viewModel = StateObject(wrappedValue: LessonViewerViewModel(
            lesson: lesson,
            courseId: courseId,
            enrollmentId: enrollmentId
        ))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Lesson Header
                lessonHeader
                
                // Learning Objectives
                if let objectives = viewModel.lesson.learningObjectives, !objectives.isEmpty {
                    objectivesSection(objectives)
                }
                
                // Prerequisites
                if let prerequisites = viewModel.lesson.prerequisites, !prerequisites.isEmpty {
                    prerequisitesSection(prerequisites)
                }
                
                // Learning Materials
                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .padding()
                } else if viewModel.contents.isEmpty {
                    emptyContentState
                } else {
                    materialsSection
                }
                
                // Quizzes Section
                if !viewModel.quizzes.isEmpty {
                    quizzesSection
                }
                
                // Mark Complete Button
                if viewModel.enrollmentId != nil {
                    markCompleteButton
                }
            }
            .padding()
        }
        .background(Color.dashboardBg)
        .navigationTitle("Lesson")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .alert("Lesson Complete!", isPresented: $showCompleteConfirmation) {
            Button("OK") { }
        } message: {
            Text("Great job! You've completed this lesson.")
        }
        .task {
            await viewModel.loadLessonContent()
        }
    }
    
    // MARK: - Lesson Header
    
    private var lessonHeader: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Completed Badge
            if let isCompleted = viewModel.currentProgress?.isCompleted, isCompleted {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 32, height: 32)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.green)
                    }
                    Text("Completed")
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                }
            }
            
            // Lesson Title
            Text(viewModel.lesson.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.dashboardTextPrimary)
            
            // Lesson Description
            Text(viewModel.lesson.lessonDescription)
                .font(.body)
                .foregroundColor(.dashboardTextSecondary)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.dashboardCard)
        )
        .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 6)
    }
    
    // MARK: - Objectives Section
    
    private func objectivesSection(_ objectives: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                
                Image(systemName: "target")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.blue)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text("Learning Objectives")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.dashboardTextPrimary)
                
                Text(objectives)
                    .font(.body)
                    .foregroundColor(.dashboardTextSecondary)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.dashboardCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1.5)
        )
        .shadow(color: Color.blue.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Prerequisites Section
    
    private func prerequisitesSection(_ prerequisites: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                
                Image(systemName: "checkmark.shield")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.orange)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text("Prerequisites")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.dashboardTextPrimary)
                
                Text(prerequisites)
                    .font(.body)
                    .foregroundColor(.dashboardTextSecondary)
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.dashboardCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.orange.opacity(0.2), lineWidth: 1.5)
        )
        .shadow(color: Color.orange.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Materials Section
    
    private var materialsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Learning Materials")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.dashboardTextPrimary)
            
            VStack(spacing: 12) {
                ForEach(viewModel.contents) { content in
                    NavigationLink(destination: ContentPlayerView(
                        content: content,
                        courseId: viewModel.courseId
                    )) {
                        ContentCard(content: content)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var emptyContentState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 50))
                .foregroundColor(.dashboardTextSecondary)
            Text("No materials available yet")
                .font(.headline)
                .foregroundColor(.dashboardTextPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Quizzes Section
    
    private var quizzesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Quizzes", systemImage: "questionmark.circle.fill")
                .font(.headline)
                .foregroundColor(.purple)
            
            VStack(spacing: 12) {
                ForEach(viewModel.quizzes) { quiz in
                    LearnerQuizCard(
                        quiz: quiz,
                        submission: viewModel.quizSubmissions[quiz.id ?? ""],
                        onRefresh: {
                            Task { await viewModel.loadLessonContent() }
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Mark Complete Button
    
    private var markCompleteButton: some View {
        Button {
            Task {
                await viewModel.markLessonComplete()
                showCompleteConfirmation = true
            }
        } label: {
            Group {
                HStack {
                    Image(systemName: viewModel.currentProgress?.isCompleted == true ? "checkmark.circle.fill" : "circle")
                    Text(viewModel.currentProgress?.isCompleted == true ? "Completed" : "Mark as Complete")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .background(
                Group {
                    if viewModel.currentProgress?.isCompleted == true {
                        Color.green.opacity(0.2)
                    } else {
                        LinearGradient(
                            colors: [.accentPrimary, .accentSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                }
            )
            .foregroundColor(viewModel.currentProgress?.isCompleted == true ? .green : .white)
            .cornerRadius(14)
        }
        .disabled(viewModel.currentProgress?.isCompleted == true)
    }
}

// MARK: - Content Card

struct ContentCard: View {
    let content: Content
    
    var body: some View {
        HStack(spacing: 16) {
            // Content Type Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(content.contentType.color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: content.contentType.icon)
                    .font(.title2)
                    .foregroundColor(content.contentType.color)
            }
            
            // Content Info
            VStack(alignment: .leading, spacing: 4) {
                Text(content.title)
                    .font(.headline)
                    .foregroundColor(.dashboardTextPrimary)
                
                Text(content.contentType.displayName)
                    .font(.caption)
                    .foregroundColor(.dashboardTextSecondary)
            }
            
            Spacer()
            
            Image(systemName: "play.circle.fill")
                .font(.title2)
                .foregroundColor(.accentPrimary)
        }
        .padding()
        .background(Color.dashboardCard)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Quiz Card

struct QuizCard: View {
    let quiz: Quiz
    
    var body: some View {
        HStack(spacing: 16) {
            // Quiz Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: "questionmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.purple)
            }
            
            // Quiz Info
            VStack(alignment: .leading, spacing: 4) {
                Text(quiz.title)
                    .font(.headline)
                    .foregroundColor(.dashboardTextPrimary)
                
                HStack(spacing: 8) {
                    Text(quiz.passingScoreDisplay)
                        .font(.caption)
                        .foregroundColor(.dashboardTextSecondary)
                    
                    if quiz.timeLimitMinutes != nil {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(quiz.timeLimitDisplay)
                            .font(.caption)
                            .foregroundColor(.dashboardTextSecondary)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.dashboardTextSecondary)
        }
        .padding()
        .background(Color.dashboardCard)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    NavigationStack {
        LessonViewerView(
            lesson: Lesson(
                id: "1",
                moduleId: "module1",
                title: "Introduction to Variables",
                lessonDescription: "Learn about variables and constants in Swift",
                orderIndex: 0,
                learningObjectives: "Understand the difference between var and let",
                prerequisites: "Basic programming knowledge",
                createdAt: Date(),
                updatedAt: Date()
            ),
            courseId: "course1",
            enrollmentId: "enrollment1"
        )
    }
}
