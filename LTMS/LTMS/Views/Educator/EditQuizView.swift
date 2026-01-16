

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
                        
                        Text("Edit Quiz")
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
                            // Quiz Information Card
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Quiz Information")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.dashboardTextSecondary)
                                
                                customTextField(title: "Quiz Title", text: $title)
                                customTextField(title: "Description (optional)", text: $description, isMultiline: true)
                            }
                            .padding()
                            .background(Color.dashboardCard)
                            .cornerRadius(20)
                            
                            // Scoring Card
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Scoring")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.dashboardTextSecondary)
                                
                                VStack(spacing: 12) {
                                    HStack {
                                        Text("Passing Score")
                                            .foregroundColor(.dashboardTextPrimary)
                                        Spacer()
                                        Text("\(Int(passingScore))%")
                                            .fontWeight(.bold)
                                            .foregroundColor(.accentBlue)
                                    }
                                    
                                    Slider(value: $passingScore, in: 0...100, step: 5)
                                        .tint(.accentBlue)
                                }
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                            }
                            .padding()
                            .background(Color.dashboardCard)
                            .cornerRadius(20)
                            
                            // Time Limit Card
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Time Limit")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.dashboardTextSecondary)
                                
                                VStack(spacing: 16) {
                                    Toggle("Enable Time Limit", isOn: $hasTimeLimit)
                                        .tint(.accentBlue)
                                        .foregroundColor(.dashboardTextPrimary)
                                    
                                    if hasTimeLimit {
                                        Divider()
                                            .background(Color.white.opacity(0.1))
                                        
                                        customTextField(
                                            title: "Duration (minutes)",
                                            text: Binding(
                                                get: { String(timeLimitMinutes) },
                                                set: { if let value = Int($0) { timeLimitMinutes = value } }
                                            )
                                        )
                                        .keyboardType(.numberPad)
                                    }
                                }
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                            }
                            .padding()
                            .background(Color.dashboardCard)
                            .cornerRadius(20)
                            
                            // Save Button
                            Button {
                                Task { await saveQuiz() }
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
                            .disabled(title.isEmpty || isLoading || !hasChanges)
                            .opacity((title.isEmpty || isLoading || !hasChanges) ? 0.6 : 1.0)
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
            Text(title)
                .font(.caption)
                .foregroundColor(.dashboardTextSecondary)
            
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
