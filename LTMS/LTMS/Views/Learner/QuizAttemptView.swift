
import SwiftUI

/// Full-screen view for learners to attempt a quiz
struct QuizAttemptView: View {
    let quiz: Quiz
    let onComplete: (QuizSubmission) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = SupabaseAuthService.shared
    
    @State private var questions: [QuizQuestion] = []
    @State private var answers: [String: String] = [:] // questionId -> selected answer
    @State private var currentQuestionIndex = 0
    @State private var isLoading = true
    @State private var isSubmitting = false
    @State private var showConfirmSubmit = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var timeRemaining: Int = 0
    @State private var timer: Timer?
    
    private var currentQuestion: QuizQuestion? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }
    
    private var answeredCount: Int {
        answers.count
    }
    
    private var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(answeredCount) / Double(questions.count)
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else if questions.isEmpty {
                    noQuestionsView
                } else {
                    quizContent
                }
            }
            .navigationTitle(quiz.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .background(Color.dashboardBg)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Exit") {
                        dismiss()
                    }
                }
                
                if quiz.timeLimitMinutes != nil && !isLoading {
                    ToolbarItem(placement: .principal) {
                        timerView
                    }
                }
            }
            .task {
                await loadQuestions()
                startTimer()
            }
            .onDisappear {
                timer?.invalidate()
            }
            .alert("Submit Quiz?", isPresented: $showConfirmSubmit) {
                Button("Cancel", role: .cancel) {}
                Button("Submit") {
                    Task { await submitQuiz() }
                }
            } message: {
                Text("You have answered \(answeredCount) of \(questions.count) questions. Submit your quiz?")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading quiz...")
                .foregroundColor(.dashboardTextSecondary)
        }
    }
    
    // MARK: - No Questions View
    
    private var noQuestionsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("No Questions")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.dashboardTextPrimary)
            
            Text("This quiz doesn't have any questions yet")
                .foregroundColor(.dashboardTextSecondary)
            
            Button("Go Back") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    // MARK: - Timer View
    
    private var timerView: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .foregroundColor(timeRemaining < 60 ? .red : .secondary)
            Text(formatTime(timeRemaining))
                .font(.headline)
                .monospacedDigit()
                .foregroundColor(timeRemaining < 60 ? .red : .dashboardTextPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(timeRemaining < 60 ? Color.red.opacity(0.1) : Color.gray.opacity(0.1))
        )
    }
    
    // MARK: - Quiz Content
    
    private var quizContent: some View {
        VStack(spacing: 0) {
            // Progress Bar
            VStack(spacing: 8) {
                ProgressView(value: progress)
                    .tint(.accentPrimary)
                
                HStack {
                    Text("Question \(currentQuestionIndex + 1) of \(questions.count)")
                        .font(.caption)
                        .foregroundColor(.dashboardTextSecondary)
                    
                    Spacer()
                    
                    Text("\(answeredCount) answered")
                        .font(.caption)
                        .foregroundColor(.accentPrimary)
                }
            }
            .padding()
            
            Divider()
            
            // Question Content
            ScrollView {
                if let question = currentQuestion {
                    questionView(question)
                }
            }
            
            Divider()
            
            // Navigation Buttons
            navigationButtons
        }
    }
    
    // MARK: - Question View
    
    private func questionView(_ question: QuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            // Question Number Badge
            HStack {
                Text("Q\(currentQuestionIndex + 1)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.accentPrimary)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                
                Text("\(question.points) pt\(question.points > 1 ? "s" : "")")
                    .font(.caption)
                    .foregroundColor(.dashboardTextSecondary)
                
                Spacer()
            }
            
            // Question Text
            Text(question.questionText)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.dashboardTextPrimary)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
            
            // Options
            if let options = question.options {
                VStack(spacing: 12) {
                    ForEach(options, id: \.self) { option in
                        optionButton(option, for: question)
                    }
                }
            }
        }
        .padding()
    }
    
    // MARK: - Option Button
    
    private func optionButton(_ option: String, for question: QuizQuestion) -> some View {
        let isSelected = answers[question.id ?? ""] == option
        
        return Button {
            if let questionId = question.id {
                answers[questionId] = option
            }
        } label: {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentPrimary : .dashboardTextSecondary)
                    .font(.title3)
                
                Text(option)
                    .foregroundColor(.dashboardTextPrimary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentPrimary.opacity(0.15) : Color.dashboardCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentPrimary : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .shadow(color: isSelected ? Color.accentPrimary.opacity(0.2) : Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            // Previous Button
            Button {
                if currentQuestionIndex > 0 {
                    currentQuestionIndex -= 1
                }
            } label: {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Previous")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.dashboardCard)
                .foregroundColor(.dashboardTextPrimary)
                .cornerRadius(12)
            }
            .disabled(currentQuestionIndex == 0)
            .opacity(currentQuestionIndex == 0 ? 0.5 : 1)
            
            // Next/Submit Button
            if currentQuestionIndex < questions.count - 1 {
                Button {
                    currentQuestionIndex += 1
                } label: {
                    HStack {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.accentPrimary, .accentSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            } else {
                Button {
                    showConfirmSubmit = true
                } label: {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Submit Quiz")
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isSubmitting)
            }
        }
        .padding()
    }
    
    // MARK: - Actions
    
    private func loadQuestions() async {
        guard let quizId = quiz.id else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            questions = try await QuizService.shared.fetchQuestionsByQuiz(quizId: quizId)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func startTimer() {
        guard let timeLimit = quiz.timeLimitMinutes else { return }
        timeRemaining = timeLimit * 60
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer?.invalidate()
                // Auto-submit when time runs out
                Task { await submitQuiz() }
            }
        }
    }
    
    private func submitQuiz() async {
        guard let quizId = quiz.id,
              let userId = authService.currentUser?.id else { return }
        
        isSubmitting = true
        defer { isSubmitting = false }
        
        do {
            let submission = try await QuizService.shared.submitQuiz(
                assessmentId: quizId,
                userId: userId,
                answers: answers
            )
            onComplete(submission)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

#Preview {
    QuizAttemptView(
        quiz: Quiz(
            id: "1",
            courseId: "course1",
            title: "Swift Basics Quiz",
            quizDescription: "Test your Swift knowledge",
            type: "quiz",
            passingScore: 70,
            timeLimitMinutes: 15,
            createdAt: Date(),
            updatedAt: Date()
        )
    ) { _ in }
}
