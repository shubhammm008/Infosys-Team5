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
            Form {
                // Question Text Section
                Section("Question") {
                    TextField("Enter your question", text: $questionText, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // Options Section
                Section {
                    ForEach(Array(options.indices), id: \.self) { index in
                        optionRow(at: index)
                    }
                } header: {
                    Text("Answer Options")
                } footer: {
                    Text("Select the correct answer by tapping the circle")
                        .font(.caption)
                }
                
                // Points Section
                Section("Points") {
                    Stepper("\(points) point\(points > 1 ? "s" : "")", value: $points, in: 1...10)
                }
                
                // Add More Options
                Section {
                    Button {
                        options.append("")
                    } label: {
                        Label("Add Option", systemImage: "plus.circle")
                    }
                    .disabled(options.count >= 6)
                }
                
                // Save Button
                Section {
                    Button {
                        Task { await saveQuestion() }
                    } label: {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Save Changes")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(!isValid || isLoading || !hasChanges)
                    .listRowBackground((isValid && hasChanges) ? Color.ltmsPrimary : Color.gray)
                    .foregroundColor(.white)
                }
            }
            .navigationTitle("Edit Question")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    @ViewBuilder
    private func optionRow(at index: Int) -> some View {
        HStack {
            Button {
                correctAnswerIndex = index
            } label: {
                Image(systemName: correctAnswerIndex == index ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(correctAnswerIndex == index ? .green : .secondary)
            }
            .buttonStyle(.plain)
            
            TextField("Option \(index + 1)", text: $options[index])
            
            // Allow removing extra options (keep minimum 2)
            if options.count > 2 && index >= 2 {
                Button {
                    removeOption(at: index)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
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
