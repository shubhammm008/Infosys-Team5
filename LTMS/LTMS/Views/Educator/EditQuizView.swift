

import SwiftUI

/// View for educators to edit an existing quiz's information
struct EditQuizView: View {
    let quiz: Quiz
    let onUpdate: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var description: String
    @State private var passingScore: Double
    @State private var hasTimeLimit: Bool
    @State private var timeLimitMinutes: Int
    
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    init(quiz: Quiz, onUpdate: @escaping () -> Void) {
        self.quiz = quiz
        self.onUpdate = onUpdate
        
        // Initialize state with existing quiz values
        _title = State(initialValue: quiz.title)
        _description = State(initialValue: quiz.quizDescription ?? "")
        _passingScore = State(initialValue: quiz.passingScore ?? 70)
        _hasTimeLimit = State(initialValue: quiz.timeLimitMinutes != nil)
        _timeLimitMinutes = State(initialValue: quiz.timeLimitMinutes ?? 30)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Basic Info Section
                Section("Quiz Information") {
                    TextField("Quiz Title", text: $title)
                    
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                // Scoring Section
                Section("Scoring") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Passing Score")
                            Spacer()
                            Text("\(Int(passingScore))%")
                                .fontWeight(.semibold)
                                .foregroundColor(.ltmsPrimary)
                        }
                        
                        Slider(value: $passingScore, in: 0...100, step: 5)
                            .tint(.ltmsPrimary)
                    }
                }
                
                // Time Limit Section
                Section("Time Limit") {
                    Toggle("Enable Time Limit", isOn: $hasTimeLimit)
                    
                    if hasTimeLimit {
                        Stepper("\(timeLimitMinutes) minutes", value: $timeLimitMinutes, in: 5...180, step: 5)
                    }
                }
                
                // Save Button
                Section {
                    Button {
                        Task { await saveQuiz() }
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
                    .disabled(title.isEmpty || isLoading || !hasChanges)
                    .listRowBackground(
                        (title.isEmpty || !hasChanges) ? Color.gray : Color.ltmsPrimary
                    )
                    .foregroundColor(.white)
                }
            }
            .navigationTitle("Edit Quiz")
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
    
    /// Check if any values have changed from the original quiz
    private var hasChanges: Bool {
        title != quiz.title ||
        description != (quiz.quizDescription ?? "") ||
        passingScore != (quiz.passingScore ?? 70) ||
        hasTimeLimit != (quiz.timeLimitMinutes != nil) ||
        (hasTimeLimit && timeLimitMinutes != (quiz.timeLimitMinutes ?? 30))
    }
    
    private func saveQuiz() async {
        guard quiz.id != nil else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        var updatedQuiz = quiz
        updatedQuiz.title = title
        updatedQuiz.quizDescription = description.isEmpty ? nil : description
        updatedQuiz.passingScore = passingScore
        updatedQuiz.timeLimitMinutes = hasTimeLimit ? timeLimitMinutes : nil
        updatedQuiz.updatedAt = Date()
        
        do {
            _ = try await QuizService.shared.updateQuiz(updatedQuiz)
            onUpdate()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

#Preview {
    EditQuizView(quiz: Quiz(
        id: "1",
        courseId: "course1",
        title: "Sample Quiz",
        quizDescription: "A sample description",
        type: "quiz",
        passingScore: 70,
        timeLimitMinutes: 30,
        createdAt: Date(),
        updatedAt: Date()
    )) { }
}
