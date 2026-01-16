

import SwiftUI

/// View for adding a new MCQ question to a quiz
struct AddQuestionView: View {
    let assessmentId: String
    let orderIndex: Int
    let onAdded: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var questionText = ""
    @State private var options: [String] = ["", "", "", ""]
    @State private var correctAnswerIndex = 0
    @State private var points: Int = 1
    
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private var isValid: Bool {
        !questionText.isEmpty &&
        options.filter { !$0.isEmpty }.count >= 2 &&
        !options[correctAnswerIndex].isEmpty
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
                    ForEach(0..<4, id: \.self) { index in
                        HStack {
                            Button {
                                correctAnswerIndex = index
                            } label: {
                                Image(systemName: correctAnswerIndex == index ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(correctAnswerIndex == index ? .green : .secondary)
                            }
                            .buttonStyle(.plain)
                            
                            TextField("Option \(index + 1)", text: $options[index])
                        }
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
                        Task { await addQuestion() }
                    } label: {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Add Question")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(!isValid || isLoading)
                    .listRowBackground(isValid ? Color.ltmsPrimary : Color.gray)
                    .foregroundColor(.white)
                }
            }
            .navigationTitle("Add Question")
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
    
    private func addQuestion() async {
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
        
        let question = QuizQuestion.createMCQ(
            assessmentId: assessmentId,
            questionText: questionText,
            options: validOptions,
            correctAnswer: options[correctAnswerIndex],
            points: points,
            orderIndex: orderIndex
        )
        
        do {
            _ = try await QuizService.shared.createQuestion(question)
            onAdded()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - True/False Question View (bonus)

struct AddTrueFalseQuestionView: View {
    let assessmentId: String
    let orderIndex: Int
    let onAdded: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var questionText = ""
    @State private var correctAnswer = true
    @State private var points: Int = 1
    
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Statement") {
                    TextField("Enter the statement", text: $questionText, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Correct Answer") {
                    Picker("The statement is", selection: $correctAnswer) {
                        Text("True").tag(true)
                        Text("False").tag(false)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Points") {
                    Stepper("\(points) point\(points > 1 ? "s" : "")", value: $points, in: 1...10)
                }
                
                Section {
                    Button {
                        Task { await addQuestion() }
                    } label: {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Add Question")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(questionText.isEmpty || isLoading)
                    .listRowBackground(questionText.isEmpty ? Color.gray : Color.ltmsPrimary)
                    .foregroundColor(.white)
                }
            }
            .navigationTitle("True/False Question")
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
    
    private func addQuestion() async {
        isLoading = true
        defer { isLoading = false }
        
        let question = QuizQuestion.createTrueFalse(
            assessmentId: assessmentId,
            questionText: questionText,
            correctAnswer: correctAnswer,
            points: points,
            orderIndex: orderIndex
        )
        
        do {
            _ = try await QuizService.shared.createQuestion(question)
            onAdded()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

#Preview {
    AddQuestionView(assessmentId: "quiz123", orderIndex: 1) { }
}
