

import SwiftUI

/// View showing quiz results after submission
struct QuizResultView: View {
    let quiz: Quiz
    let submission: QuizSubmission
    
    @Environment(\.dismiss) private var dismiss
    @State private var questions: [QuizQuestion] = []
    @State private var isLoading = true
    
    private var score: Double {
        submission.score ?? 0
    }
    
    private var passed: Bool {
        submission.passed ?? false
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Result Header
                    resultHeader
                    
                    // Score Card
                    scoreCard
                    
                    // Feedback
                    if let feedback = submission.feedback {
                        feedbackCard(feedback)
                    }
                    
                    // Questions Review
                    if !isLoading && !questions.isEmpty {
                        questionsReview
                    }
                }
                .padding()
            }
            .background(Color.ltmsBackground)
            .navigationTitle("Quiz Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadQuestions()
            }
        }
    }
    
    // MARK: - Result Header
    
    private var resultHeader: some View {
        VStack(spacing: 16) {
            // Animated Icon
            ZStack {
                Circle()
                    .fill(passed ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Image(systemName: passed ? "checkmark.seal.fill" : "xmark.seal.fill")
                    .font(.system(size: 50))
                    .foregroundColor(passed ? .green : .red)
            }
            
            Text(passed ? "Congratulations!" : "Keep Trying!")
                .font(.title)
                .fontWeight(.bold)
            
            Text(passed ? "You passed the quiz" : "You didn't pass this time")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical)
    }
    
    // MARK: - Score Card
    
    private var scoreCard: some View {
        VStack(spacing: 16) {
            // Score Display
            HStack(spacing: 20) {
                VStack {
                    Text(String(format: "%.0f%%", score))
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(passed ? .green : .red)
                    Text("Your Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .frame(height: 60)
                
                VStack {
                    Text(quiz.passingScoreDisplay)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text("Passing Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Score Progress Bar
            VStack(alignment: .leading, spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.2))
                        
                        // Score Progress
                        RoundedRectangle(cornerRadius: 8)
                            .fill(passed ? Color.green : Color.red)
                            .frame(width: geometry.size.width * (score / 100))
                        
                        // Passing Score Marker
                        if let passingScore = quiz.passingScore {
                            Rectangle()
                                .fill(Color.orange)
                                .frame(width: 3)
                                .offset(x: geometry.size.width * (passingScore / 100) - 1.5)
                        }
                    }
                }
                .frame(height: 12)
                
                // Legend
                HStack {
                    Circle()
                        .fill(passed ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text("Your score")
                        .font(.caption2)
                    
                    Spacer()
                    
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 8, height: 8)
                    Text("Passing threshold")
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.ltmsCardBackground)
        .cornerRadius(16)
    }
    
    // MARK: - Feedback Card
    
    private func feedbackCard(_ feedback: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Feedback")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(feedback)
                    .font(.subheadline)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Questions Review
    
    private var questionsReview: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Question Review")
                .font(.headline)
            
            ForEach(Array(questions.enumerated()), id: \.element.id) { index, question in
                questionReviewCard(question, number: index + 1)
            }
        }
    }
    
    private func questionReviewCard(_ question: QuizQuestion, number: Int) -> some View {
        let userAnswer = submission.answers?[question.id ?? ""]
        let isCorrect = question.isCorrect(userAnswer ?? "")
        
        return VStack(alignment: .leading, spacing: 12) {
            // Question Header
            HStack {
                Text("Q\(number)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(isCorrect ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    .foregroundColor(isCorrect ? .green : .red)
                    .cornerRadius(6)
                
                Spacer()
                
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isCorrect ? .green : .red)
            }
            
            // Question Text
            Text(question.questionText)
                .font(.subheadline)
            
            // Options with highlighting
            if let options = question.options {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(options, id: \.self) { option in
                        optionReviewRow(
                            option: option,
                            isUserAnswer: userAnswer == option,
                            isCorrectAnswer: option == question.correctAnswer
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color.ltmsCardBackground)
        .cornerRadius(12)
    }
    
    private func optionReviewRow(option: String, isUserAnswer: Bool, isCorrectAnswer: Bool) -> some View {
        HStack(spacing: 8) {
            // Icon
            if isCorrectAnswer {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else if isUserAnswer {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.secondary.opacity(0.5))
            }
            
            // Option Text
            Text(option)
                .font(.caption)
                .foregroundColor(
                    isCorrectAnswer ? .green :
                    isUserAnswer ? .red : .secondary
                )
                .fontWeight(isCorrectAnswer || isUserAnswer ? .medium : .regular)
            
            Spacer()
            
            // Labels
            if isCorrectAnswer {
                Text("Correct")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(4)
            }
            
            if isUserAnswer && !isCorrectAnswer {
                Text("Your answer")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.red.opacity(0.2))
                    .foregroundColor(.red)
                    .cornerRadius(4)
            }
        }
    }
    
    // MARK: - Load Questions
    
    private func loadQuestions() async {
        guard let quizId = quiz.id else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            questions = try await QuizService.shared.fetchQuestionsByQuiz(quizId: quizId)
        } catch {
            print("Error loading questions: \(error)")
        }
    }
}

#Preview {
    QuizResultView(
        quiz: Quiz(
            id: "1",
            courseId: "course1",
            title: "Swift Basics Quiz",
            quizDescription: nil,
            type: "quiz",
            passingScore: 70,
            timeLimitMinutes: nil,
            createdAt: Date(),
            updatedAt: Date()
        ),
        submission: QuizSubmission(
            id: "sub1",
            assessmentId: "1",
            userId: "user1",
            submittedAt: Date(),
            score: 85,
            passed: true,
            answers: [:],
            feedback: "Great job! You've demonstrated a solid understanding of Swift basics.",
            gradedBy: nil,
            gradedAt: Date()
        )
    )
}
