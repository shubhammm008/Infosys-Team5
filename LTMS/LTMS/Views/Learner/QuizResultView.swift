

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

            .background(Color.dashboardBg)
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
        VStack(spacing: 24) {
            // Animated Icon with Glow
            ZStack {
                Circle()
                    .fill(passed ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .blur(radius: 10)
                
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: passed ? [.green.opacity(0.6), .green.opacity(0.1)] : [.red.opacity(0.6), .red.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: passed ? "trophy.fill" : "xmark.seal.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(
                        LinearGradient(
                            colors: passed ? [.green, .mint] : [.red, .orange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .shadow(color: passed ? Color.green.opacity(0.3) : Color.red.opacity(0.3), radius: 15)
            
            VStack(spacing: 8) {
                Text(passed ? "Congratulations!" : "Keep Learning")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.dashboardTextPrimary)
                
                Text(passed ? "You've successfully mastered this topic" : "Don't give up! Review the material and try again")
                    .font(.subheadline)
                    .foregroundColor(.dashboardTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Score Card
    
    private var scoreCard: some View {
        VStack(spacing: 24) {
            // Score Display with Circular Progress
            HStack(spacing: 30) {
                // Circular Progress
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 12)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: score / 100)
                        .stroke(
                            LinearGradient(
                                colors: passed ? [.green, .mint] : [.red, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 2) {
                        Text(String(format: "%.0f%%", score))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.dashboardTextPrimary)
                        Text("Score")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.dashboardTextSecondary)
                    }
                }
                
                // Stats
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Passing Score")
                            .font(.caption)
                            .foregroundColor(.dashboardTextSecondary)
                        Text(quiz.passingScoreDisplay)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.dashboardTextPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Status")
                            .font(.caption)
                            .foregroundColor(.dashboardTextSecondary)
                        HStack {
                            Image(systemName: passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                            Text(passed ? "PASSED" : "FAILED")
                        }
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(passed ? .green : .red)
                    }
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.dashboardCard)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Feedback Card
    
    private func feedbackCard(_ feedback: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.yellow.opacity(0.2))
                    .frame(width: 44, height: 44)
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 20))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Instructor Feedback")
                    .font(.headline)
                    .foregroundColor(.dashboardTextPrimary)
                Text(feedback)
                    .font(.subheadline)
                    .foregroundColor(.dashboardTextSecondary)
                    .lineSpacing(4)
            }
            
            Spacer()
        }
        .padding(20)
        .background(Color.dashboardCard)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Questions Review
    
    private var questionsReview: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Question Review")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.dashboardTextPrimary)
            
            ForEach(Array(questions.enumerated()), id: \.element.id) { index, question in
                questionReviewCard(question, number: index + 1)
            }
        }
    }
    
    private func questionReviewCard(_ question: QuizQuestion, number: Int) -> some View {
        let userAnswer = submission.answers?[question.id ?? ""]
        let isCorrect = question.isCorrect(userAnswer ?? "")
        
        return VStack(alignment: .leading, spacing: 16) {
            // Question Header
            HStack {
                HStack(spacing: 12) {
                    Text("Q\(number)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(isCorrect ? Color.green : Color.red)
                        .clipShape(Circle())
                    
                    Text(isCorrect ? "Correct" : "Incorrect")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(isCorrect ? .green : .red)
                }
                
                Spacer()
                
                Text("\(question.points) pts")
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.1))
                    .foregroundColor(.dashboardTextSecondary)
                    .cornerRadius(8)
            }
            
            // Question Text
            Text(question.questionText)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.dashboardTextPrimary)
                .padding(.vertical, 4)
            
            // Options with highlighting
            if let options = question.options {
                VStack(alignment: .leading, spacing: 12) {
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
        .padding(20)
        .background(Color.dashboardCard)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private func optionReviewRow(option: String, isUserAnswer: Bool, isCorrectAnswer: Bool) -> some View {
        var backgroundColor: Color = Color.dashboardBg.opacity(0.5)
        if isCorrectAnswer {
            backgroundColor = Color.green.opacity(0.05)
        } else if isUserAnswer {
            backgroundColor = Color.red.opacity(0.05)
        }
        
        var borderColor: Color = .clear
        if isCorrectAnswer {
            borderColor = Color.green.opacity(0.3)
        } else if isUserAnswer {
            borderColor = Color.red.opacity(0.3)
        }
        
        var textColor: Color = .dashboardTextPrimary
        if isCorrectAnswer {
            textColor = .green
        } else if isUserAnswer {
            textColor = .red
        }
        
        return HStack(spacing: 12) {
            // Icon
            if isCorrectAnswer {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            } else if isUserAnswer {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.title3)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.dashboardTextSecondary)
                    .font(.title3)
            }
            
            // Option Text
            Text(option)
                .font(.body)
                .foregroundColor(textColor)
                .fontWeight(isCorrectAnswer || isUserAnswer ? .semibold : .regular)
            
            Spacer()
            
            // Labels
            if isCorrectAnswer {
                Text("Correct Answer")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.15))
                    .foregroundColor(.green)
                    .cornerRadius(6)
            } else if isUserAnswer {
                Text("You Selected")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.15))
                    .foregroundColor(.red)
                    .cornerRadius(6)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 1)
        )
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
