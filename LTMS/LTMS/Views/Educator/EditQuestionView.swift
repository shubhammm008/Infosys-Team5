//
//  EditQuestionView.swift
//  LTMS
//
//   - Educator View
//

import SwiftUI

/// View for educators to edit an existing quiz question
struct EditQuestionView: View {
    let question: QuizQuestion
    let onUpdate: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var questionText: String
    @State private var options: [String]
    @State private var correctAnswerIndex: Int
    @State private var points: Int
    
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Cache original values for comparison
    private let originalQuestionText: String
    private let originalOptions: [String]
    private let originalCorrectAnswer: String
    private let originalPoints: Int
    
    init(question: QuizQuestion, onUpdate: @escaping () -> Void) {
        self.question = question
        self.onUpdate = onUpdate
        
        // Cache original values
        self.originalQuestionText = question.questionText
        self.originalOptions = question.options ?? []
        self.originalCorrectAnswer = question.correctAnswer
        self.originalPoints = question.points
        
        // Initialize state with existing question values
        _questionText = State(initialValue: question.questionText)
        
        // Handle options - ensure at least 4 slots
        var existingOptions = question.options ?? []
        while existingOptions.count < 4 {
            existingOptions.append("")
        }
        _options = State(initialValue: existingOptions)
        
        // Find correct answer index
        let correctIndex = existingOptions.firstIndex(of: question.correctAnswer) ?? 0
        _correctAnswerIndex = State(initialValue: correctIndex)
        
        _points = State(initialValue: question.points)
    }
    
    private var isValid: Bool {
        !questionText.isEmpty &&
        options.filter { !$0.isEmpty }.count >= 2 &&
        correctAnswerIndex < options.count &&
        !options[correctAnswerIndex].isEmpty
    }
    
    private var hasChanges: Bool {
        if questionText != originalQuestionText { return true }
        if points != originalPoints { return true }
        
        let currentCorrectAnswer = correctAnswerIndex < options.count ? options[correctAnswerIndex] : ""
        if currentCorrectAnswer != originalCorrectAnswer { return true }
        
        let validOptions = options.filter { !$0.isEmpty }
        if validOptions != originalOptions { return true }
        
        return false
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.dashboardBg.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Header
                    HStack {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(.dashboardTextSecondary)
                        
                        Spacer()
                        
                        Text("Edit Question")
                            .font(.headline)
                            .foregroundColor(.dashboardTextPrimary)
                        
                        Spacer()
                        
                        // Invisible spacer for balance
                        Button("Cancel") { }
                            .opacity(0)
                    }
                    .padding()
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Question Text Card
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Question")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.dashboardTextSecondary)
                                
                                customTextField(title: "Enter your question", text: $questionText, isMultiline: true)
                            }
                            .padding()
                            .background(Color.dashboardCard)
                            .cornerRadius(20)
                            
                            // Options Card
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Answer Options")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.dashboardTextSecondary)
                                    
                                    Spacer()
                                    
                                    Text("Select correct answer")
                                        .font(.caption)
                                        .foregroundColor(.dashboardTextSecondary)
                                }
                                
                                VStack(spacing: 12) {
                                    ForEach(Array(options.indices), id: \.self) { index in
                                        optionRow(at: index)
                                    }
                                }
                                
                                // Add Option Button
                                if options.count < 6 {
                                    Button {
                                        options.append("")
                                    } label: {
                                        HStack {
                                            Image(systemName: "plus.circle.fill")
                                            Text("Add Option")
                                        }
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.accentBlue)
                                        .padding(.top, 4)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.dashboardCard)
                            .cornerRadius(20)
                            
                            // Points Card
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Points")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.dashboardTextSecondary)
                                
                                customTextField(
                                    title: "Points value",
                                    text: Binding(
                                        get: { String(points) },
                                        set: { if let value = Int($0) { points = value } }
                                    )
                                )
                                .keyboardType(.numberPad)
                            }
                            .padding()
                            .background(Color.dashboardCard)
                            .cornerRadius(20)
                            
                            // Save Button
                            Button {
                                Task { await saveQuestion() }
                            } label: {
                                ZStack {
                                    if isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("Save Changes")
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
                            .disabled(!isValid || isLoading || !hasChanges)
                            .opacity((!isValid || isLoading || !hasChanges) ? 0.6 : 1.0)
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
    
    @ViewBuilder
    private func customTextField(title: String, text: Binding<String>, isMultiline: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if !title.isEmpty && title != "Points value" && title != "Enter your question" {
                 Text(title)
                    .font(.caption)
                    .foregroundColor(.dashboardTextSecondary)
            }
            
            if isMultiline {
                TextEditor(text: text)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 100)
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
    
    @ViewBuilder
    private func optionRow(at index: Int) -> some View {
        HStack(spacing: 12) {
            Button {
                correctAnswerIndex = index
            } label: {
                Image(systemName: correctAnswerIndex == index ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(correctAnswerIndex == index ? .green : .dashboardTextSecondary)
            }
            .buttonStyle(.plain)
            
            TextField("Option \(index + 1)", text: $options[index])
                .padding(12)
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                .foregroundColor(.dashboardTextPrimary)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(correctAnswerIndex == index ? Color.green.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
                )
            
        }
    }
    
    private func removeOption(at index: Int) {
        // Adjust correct answer index if needed
        if index == correctAnswerIndex {
            correctAnswerIndex = 0
        } else if index < correctAnswerIndex {
            correctAnswerIndex -= 1
        }
        options.remove(at: index)
    }
    
    private func saveQuestion() async {
        // Filter out empty options
        let validOptions = options.filter { !$0.isEmpty }
        
        guard validOptions.count >= 2 else {
            errorMessage = "Please provide at least 2 options"
            showError = true
            return
        }
        
        guard correctAnswerIndex < options.count && !options[correctAnswerIndex].isEmpty else {
            errorMessage = "Please select a valid correct answer"
            showError = true
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        var updatedQuestion = question
        updatedQuestion.questionText = questionText
        updatedQuestion.options = validOptions
        updatedQuestion.correctAnswer = options[correctAnswerIndex]
        updatedQuestion.points = points
        
        do {
            _ = try await QuizService.shared.updateQuestion(updatedQuestion)
            onUpdate()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

#Preview {
    EditQuestionView(question: QuizQuestion(
        id: "1",
        assessmentId: "quiz1",
        questionText: "What is SwiftUI?",
        questionType: "multiple_choice",
        options: ["A framework", "A language", "An IDE", "A device"],
        correctAnswer: "A framework",
        points: 1,
        orderIndex: 1,
        createdAt: Date()
    )) { }
}
