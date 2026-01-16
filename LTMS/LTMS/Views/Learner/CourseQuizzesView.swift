

import SwiftUI

/// View for learners to see all quizzes for an enrolled course
struct CourseQuizzesView: View {
    let course: Course
    
    @StateObject private var authService = SupabaseAuthService.shared
    @State private var quizzes: [Quiz] = []
    @State private var submissions: [String: QuizSubmission] = [:] // assessmentId -> submission
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading quizzes...")
            } else if quizzes.isEmpty {
                emptyState
            } else {
                quizList
            }
        }
        .navigationTitle("Quizzes")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadQuizzes()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Quizzes Available")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("The instructor hasn't added any quizzes to this course yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
    
    // MARK: - Quiz List
    
    private var quizList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(quizzes) { quiz in
                    LearnerQuizCard(
                        quiz: quiz,
                        submission: submissions[quiz.id ?? ""],
                        onRefresh: {
                            Task { await loadQuizzes() }
                        }
                    )
                }
            }
            .padding()
        }
        .background(Color.ltmsBackground)
        .refreshable {
            await loadQuizzes()
        }
    }
    
    // MARK: - Load Data
    
    private func loadQuizzes() async {
        guard let courseId = course.id,
              let userId = authService.currentUser?.id else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Fetch published quizzes for this course
            quizzes = try await QuizService.shared.fetchQuizzesByCourse(courseId: courseId)
            
            // Fetch user's submissions
            let allSubmissions = try await QuizService.shared.fetchSubmissionsByUser(userId: userId)
            for submission in allSubmissions {
                submissions[submission.assessmentId] = submission
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Learner Quiz Card

struct LearnerQuizCard: View {
    let quiz: Quiz
    let submission: QuizSubmission?
    let onRefresh: () -> Void
    
    @State private var showQuizAttempt = false
    @State private var showQuizResult = false
    
    private var hasAttempted: Bool {
        submission != nil
    }
    
    private var hasPassed: Bool {
        submission?.passed ?? false
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(quiz.title)
                        .font(.headline)
                    
                    if let description = quiz.quizDescription, !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                // Status Badge
                statusBadge
            }
            
            // Quiz Info
            HStack(spacing: 20) {
                Label(quiz.passingScoreDisplay, systemImage: "checkmark.circle")
                Label(quiz.timeLimitDisplay, systemImage: "clock")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            
            // Previous Score (if attempted)
            if let submission = submission {
                HStack {
                    Text("Your Score:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(submission.scoreDisplay)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(hasPassed ? .green : .red)
                    
                    Spacer()
                    
                    Button("View Results") {
                        showQuizResult = true
                    }
                    .font(.caption)
                    .foregroundColor(.ltmsPrimary)
                }
                .padding(.top, 4)
            }
            
            // Action Button
            if hasAttempted {
                HStack {
                    if hasPassed {
                        Label("Completed", systemImage: "checkmark.seal.fill")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    } else {
                        Button {
                            showQuizAttempt = true
                        } label: {
                            Text("Retry Quiz")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                }
            } else {
                Button {
                    showQuizAttempt = true
                } label: {
                    Text("Start Quiz")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [.ltmsPrimary, .ltmsSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color.ltmsCardBackground)
        .cornerRadius(16)
        .fullScreenCover(isPresented: $showQuizAttempt) {
            QuizAttemptView(quiz: quiz) { _ in
                onRefresh()
            }
        }
        .sheet(isPresented: $showQuizResult) {
            if let submission = submission {
                QuizResultView(quiz: quiz, submission: submission)
            }
        }
    }
    
    private var statusBadge: some View {
        Group {
            if hasPassed {
                Text("Passed")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(8)
            } else if hasAttempted {
                Text("Try Again")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .cornerRadius(8)
            } else {
                Text("Not Started")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.gray)
                    .cornerRadius(8)
            }
        }
    }
}

#Preview {
    NavigationStack {
        CourseQuizzesView(course: Course(
            id: "1",
            organizationId: "org1",
            title: "iOS Development",
            courseDescription: "Learn iOS",
            level: .beginner,
            durationHours: 40,
            thumbnailURL: nil,
            isPublished: true,
            createdById: "user1",
            assignedEducatorId: "educator1",
            createdAt: Date(),
            updatedAt: Date(),
            scheduledStartDate: nil,
            scheduledEndDate: nil,
            enrollmentDeadline: nil,
            maxEnrollments: nil,
            isVisibleInCatalog: true
        ))
    }
}
