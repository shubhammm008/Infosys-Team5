//
//  AIQuestionGeneratorView.swift
//  LTMS
//
//  UI for generating quiz questions using AI

import SwiftUI

struct AIQuestionGeneratorView: View {
    let quiz: Quiz
    let onQuestionsGenerated: ([QuizQuestion]) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var aiService = AIQuestionGeneratorService.shared
    
    @State private var contentInput = ""
    @State private var questionCount = 5
    @State private var difficulty: QuestionDifficulty = .medium
    @State private var generatedQuestions: [QuizQuestion] = []
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isGenerating = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.dashboardBg.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(.dashboardTextSecondary)
                        
                        Spacer()
                        
                        Text("AI Question Generator")
                            .font(.headline)
                            .foregroundColor(.dashboardTextPrimary)
                        
                        Spacer()
                        
                        Button("Cancel") {}
                            .opacity(0)
                    }
                    .padding()
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // AI Icon Header
                            VStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.accentPurple.opacity(0.3), Color.accentBlue.opacity(0.3)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 80, height: 80)
                                    
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 40))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [Color.accentPurple, Color.accentBlue],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }
                                
                                Text("Generate Questions with AI")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.dashboardTextPrimary)
                                
                                Text("Provide content or topic to generate quiz questions automatically")
                                    .font(.subheadline)
                                    .foregroundColor(.dashboardTextSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .padding(.vertical)
                            
                            if generatedQuestions.isEmpty {
                                // Input Section
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Content or Topic")
                                        .font(.headline)
                                        .foregroundColor(.dashboardTextSecondary)
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Enter lesson content, topic, or key concepts")
                                            .font(.caption)
                                            .foregroundColor(.dashboardTextSecondary)
                                        
                                        TextEditor(text: $contentInput)
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
                                            .overlay(alignment: .topLeading) {
                                                if contentInput.isEmpty {
                                                    Text("Example: \"Introduction to Swift programming language, covering variables, constants, data types, and basic operators...\"")
                                                        .foregroundColor(.dashboardTextSecondary.opacity(0.5))
                                                        .padding(.horizontal, 16)
                                                        .padding(.vertical, 20)
                                                        .allowsHitTesting(false)
                                                }
                                            }
                                    }
                                }
                                .padding()
                                .background(Color.dashboardCard)
                                .cornerRadius(20)
                                
                                // Settings Section
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Generation Settings")
                                        .font(.headline)
                                        .foregroundColor(.dashboardTextSecondary)
                                    
                                    VStack(spacing: 20) {
                                        // Question Count
                                        HStack {
                                            Text("Number of Questions")
                                                .foregroundColor(.dashboardTextPrimary)
                                            Spacer()
                                            Stepper("\(questionCount)", value: $questionCount, in: 1...10)
                                                .foregroundColor(.accentBlue)
                                        }
                                        
                                        Divider()
                                            .background(Color.white.opacity(0.1))
                                        
                                        // Difficulty
                                        VStack(alignment: .leading, spacing: 12) {
                                            Text("Difficulty Level")
                                                .foregroundColor(.dashboardTextPrimary)
                                            
                                            Picker("Difficulty", selection: $difficulty) {
                                                ForEach(QuestionDifficulty.allCases, id: \.self) { level in
                                                    Text(level.rawValue).tag(level)
                                                }
                                            }
                                            .pickerStyle(.segmented)
                                            .colorScheme(.dark)
                                            
                                            Text(difficulty.description)
                                                .font(.caption)
                                                .foregroundColor(.dashboardTextSecondary)
                                        }
                                    }
                                }
                                .padding()
                                .background(Color.dashboardCard)
                                .cornerRadius(20)
                                
                                // Generate Button
                                Button {
                                    Task { await generateQuestions() }
                                } label: {
                                    HStack {
                                        if isGenerating {
                                            ProgressView()
                                                .tint(.white)
                                        } else {
                                            Image(systemName: "sparkles")
                                            Text("Generate Questions")
                                        }
                                    }
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(
                                        LinearGradient(
                                            colors: contentInput.isEmpty ? [.gray] : [Color.accentPurple, Color.accentBlue],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                                    .shadow(color: contentInput.isEmpty ? .clear : Color.accentBlue.opacity(0.3), radius: 10, x: 0, y: 5)
                                }
                                .disabled(contentInput.isEmpty || isGenerating)
                                .opacity(contentInput.isEmpty || isGenerating ? 0.6 : 1)
                                
                                if isGenerating {
                                    HStack {
                                        ProgressView()
                                            .tint(.accentBlue)
                                        Text(aiService.generationProgress)
                                            .font(.subheadline)
                                            .foregroundColor(.dashboardTextSecondary)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.dashboardCard)
                                    .cornerRadius(12)
                                }
                                
                            } else {
                                // Preview Generated Questions
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Generated \(generatedQuestions.count) Questions")
                                            .font(.headline)
                                            .foregroundColor(.dashboardTextPrimary)
                                        Spacer()
                                    }
                                    
                                    Text("Review the questions below. You can edit them after adding to your quiz.")
                                        .font(.caption)
                                        .foregroundColor(.dashboardTextSecondary)
                                }
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(12)
                                
                                // Questions Preview
                                ForEach(Array(generatedQuestions.enumerated()), id: \.element.id) { index, question in
                                    AIQuestionPreviewCard(question: question, number: index + 1)
                                }
                                
                                // Action Buttons
                                VStack(spacing: 12) {
                                    Button {
                                        onQuestionsGenerated(generatedQuestions)
                                        dismiss()
                                    } label: {
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                            Text("Add All Questions")
                                        }
                                        .fontWeight(.bold)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 56)
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(16)
                                        .shadow(color: Color.green.opacity(0.3), radius: 10, x: 0, y: 5)
                                    }
                                    
                                    Button {
                                        generatedQuestions = []
                                        contentInput = ""
                                    } label: {
                                        Text("Generate Different Questions")
                                            .foregroundColor(.dashboardTextSecondary)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func generateQuestions() async {
        guard let quizId = quiz.id else { return }
        
        isGenerating = true
        defer { isGenerating = false }
        
        do {
            generatedQuestions = try await aiService.generateQuestions(
                from: contentInput,
                count: questionCount,
                difficulty: difficulty,
                quizId: quizId
            )
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Question Preview Card

struct AIQuestionPreviewCard: View {
    let question: QuizQuestion
    let number: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Q\(number)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        LinearGradient(
                            colors: [Color.accentPurple, Color.accentBlue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(6)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.caption2)
                    Text("AI Generated")
                        .font(.caption2)
                }
                .foregroundColor(.accentPurple)
            }
            
            Text(question.questionText)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.dashboardTextPrimary)
            
            if let options = question.options {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(option == question.correctAnswer ? Color.green.opacity(0.2) : Color.white.opacity(0.05))
                                    .frame(width: 24, height: 24)
                                
                                Text(String(UnicodeScalar(65 + index)!))
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(option == question.correctAnswer ? .green : .dashboardTextSecondary)
                            }
                            
                            Text(option)
                                .font(.caption)
                                .foregroundColor(option == question.correctAnswer ? .green : .dashboardTextSecondary)
                            
                            if option == question.correctAnswer {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.dashboardCard)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [Color.accentPurple.opacity(0.3), Color.accentBlue.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

#Preview {
    AIQuestionGeneratorView(
        quiz: Quiz(
            id: "1",
            courseId: "course1",
            lessonId: nil,
            title: "Swift Basics Quiz",
            quizDescription: nil,
            type: "quiz",
            passingScore: 70,
            timeLimitMinutes: nil,
            createdAt: Date(),
            updatedAt: Date()
        ),
        onQuestionsGenerated: { _ in }
    )
}
