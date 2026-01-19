

import SwiftUI

/// View for educators to create a new quiz
struct CreateQuizView: View {
    let course: Course
    let lesson: Lesson?  // Optional - if provided, quiz is for this lesson
    let onCreated: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = SupabaseAuthService.shared
    
    @State private var title = ""
    @State private var description = ""
    @State private var passingScore: Double = 70
    @State private var hasTimeLimit = false
    @State private var timeLimitMinutes: Int = 30

    
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var createdQuiz: Quiz?
    @State private var showAddQuestions = false
    
    init(course: Course, lesson: Lesson? = nil, onCreated: @escaping () -> Void) {
        self.course = course
        self.lesson = lesson
        self.onCreated = onCreated
    }
    
    var body: some View {
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
                    
                    Text(lesson != nil ? "Create Lesson Quiz" : "Create Quiz")
                        .font(.headline)
                        .foregroundColor(.dashboardTextPrimary)
                    
                    Spacer()
                    
                    // Invisible button for balance
                    Button("Cancel") {}
                        .opacity(0)
                        .accessibilityHidden(true)
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Quiz Info Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Quiz Information")
                                .font(.headline)
                                .foregroundColor(.dashboardTextSecondary)
                            
                            VStack(spacing: 16) {
                                customTextField(title: "Quiz Title", text: $title)
                                customTextField(title: "Description (optional)", text: $description, isMultiline: true)
                                
                                if let lessonTitle = lesson?.title {
                                    HStack {
                                        Text("For Lesson")
                                            .foregroundColor(.dashboardTextSecondary)
                                        Spacer()
                                        Text(lessonTitle)
                                            .foregroundColor(.dashboardTextPrimary)
                                    }
                                    .padding(.top, 4)
                                    .font(.subheadline)
                                }
                            }
                            .padding()
                            .background(Color.dashboardCard)
                            .cornerRadius(16)
                        }
                        
                        // Scoring Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Scoring")
                                .font(.headline)
                                .foregroundColor(.dashboardTextSecondary)
                            
                            VStack(spacing: 20) {
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
                            .background(Color.dashboardCard)
                            .cornerRadius(16)
                        }
                        
                        // Time Limit Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Time Limit")
                                .font(.headline)
                                .foregroundColor(.dashboardTextSecondary)
                            
                            VStack(spacing: 20) {
                                Toggle(isOn: $hasTimeLimit) {
                                    Text("Enable Time Limit")
                                        .foregroundColor(.dashboardTextPrimary)
                                }
                                .tint(.accentBlue)
                                
                                if hasTimeLimit {
                                    HStack {
                                        Text("Duration")
                                            .foregroundColor(.dashboardTextSecondary)
                                        Spacer()
                                        Stepper("\(timeLimitMinutes) minutes", value: $timeLimitMinutes, in: 5...180, step: 5)
                                            .foregroundColor(.dashboardTextPrimary)
                                            .colorScheme(.dark) // Force dark mode for stepper
                                    }
                                }
                            }
                            .padding()
                            .background(Color.dashboardCard)
                            .cornerRadius(16)
                        }
                        
                        // Create Button
                        Button {
                            Task { await createQuiz() }
                        } label: {
                            ZStack {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Create Quiz")
                                        .fontWeight(.bold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: title.isEmpty ? [.gray] : [Color.accentBlue, Color.accentPurple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(color: title.isEmpty ? .clear : Color.accentBlue.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .disabled(title.isEmpty || isLoading)
                        .opacity(title.isEmpty ? 0.6 : 1)
                        .padding(.vertical)
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAddQuestions) {
            if let quiz = createdQuiz, quiz.id != nil {
                NavigationStack {
                    AddQuestionsFlowView(quiz: quiz) {
                        onCreated()
                        dismiss()
                    }
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
    
    @ViewBuilder
    private func customTextField(title: String, text: Binding<String>, isMultiline: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if !text.wrappedValue.isEmpty {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.dashboardTextSecondary)
            }
            
            if isMultiline {
                ZStack(alignment: .topLeading) {
                    if text.wrappedValue.isEmpty {
                        Text(title)
                            .foregroundColor(.dashboardTextSecondary.opacity(0.5))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                    }
                    
                    TextEditor(text: text)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color.clear)
                        .foregroundColor(.dashboardTextPrimary)
                }
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
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
                    .placeholder(when: text.wrappedValue.isEmpty) {
                        Text(title).foregroundColor(.dashboardTextSecondary.opacity(0.5))
                    }
            }
        }
    }
    
    private func createQuiz() async {
        guard let courseId = course.id else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        let quiz = Quiz(
            id: nil,
            courseId: courseId,
            lessonId: lesson?.id,  // Include lessonId if creating for a specific lesson
            title: title,
            quizDescription: description.isEmpty ? nil : description,
            type: "quiz",
            passingScore: passingScore,
            timeLimitMinutes: hasTimeLimit ? timeLimitMinutes : nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        do {
            createdQuiz = try await QuizService.shared.createQuiz(quiz)
            showAddQuestions = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Add Questions Flow View

struct AddQuestionsFlowView: View {
    let quiz: Quiz
    let onComplete: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var questions: [QuizQuestion] = []
    @State private var showAddQuestion = false
    @State private var showAIGenerator = false  // NEW: AI generator state
    
    var body: some View {
        ZStack {
            Color.dashboardBg.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Content
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                        .padding(.top, 20)
                    
                    VStack(spacing: 4) {
                        Text("Quiz Created!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.dashboardTextPrimary)
                        
                        Text("Now add questions to your quiz")
                            .font(.subheadline)
                            .foregroundColor(.dashboardTextSecondary)
                    }
                }
                .padding()
                
                // Questions List
                if questions.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "text.badge.plus")
                            .font(.system(size: 50))
                            .foregroundColor(.dashboardTextSecondary.opacity(0.5))
                        Text("No questions yet")
                            .foregroundColor(.dashboardTextSecondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(Array(questions.enumerated()), id: \.element.id) { index, question in
                                QuestionCardView(question: question, number: index + 1)
                            }
                        }
                        .padding()
                    }
                }
                
                // Bottom Buttons
                VStack(spacing: 16) {
                    // NEW: AI Generator Button
                    Button {
                        showAIGenerator = true
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Generate with AI")
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.accentPurple.opacity(0.2), Color.accentBlue.opacity(0.2)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.accentPurple)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.accentPurple, Color.accentBlue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                    }
                    
                    Button {
                        showAddQuestion = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Question Manually")
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .foregroundColor(.accentBlue)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.accentBlue.opacity(0.5), lineWidth: 1)
                        )
                    }
                    
                    if !questions.isEmpty {
                        Button {
                            onComplete()
                        } label: {
                            Text("Done")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(16)
                                .shadow(color: Color.green.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                    }
                    
                    if questions.isEmpty {
                        Button {
                            onComplete()
                        } label: {
                            Text("Skip for Now")
                                .foregroundColor(.dashboardTextSecondary)
                        }
                    }
                }
                .padding()
                .background(Color.dashboardCard)
                .cornerRadius(24, corners: [.topLeft, .topRight])
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAddQuestion) {
            if let quizId = quiz.id {
                AddQuestionView(assessmentId: quizId, orderIndex: questions.count + 1) {
                    Task { await loadQuestions() }
                }
            }
        }
        .sheet(isPresented: $showAIGenerator) {
            // NEW: AI Generator Sheet
            AIQuestionGeneratorView(quiz: quiz) { generatedQuestions in
                Task {
                    await saveGeneratedQuestions(generatedQuestions)
                }
            }
        }
        .task {
            await loadQuestions()
        }
    }
    
    private func loadQuestions() async {
        guard let quizId = quiz.id else { return }
        do {
            questions = try await QuizService.shared.fetchQuestionsByQuiz(quizId: quizId)
        } catch {
            print("Error loading questions: \(error)")
        }
    }
    
    // NEW: Save AI-generated questions
    private func saveGeneratedQuestions(_ generatedQuestions: [QuizQuestion]) async {
        for question in generatedQuestions {
            do {
                _ = try await QuizService.shared.createQuestion(question)
            } catch {
                print("Error saving AI-generated question: \(error)")
            }
        }
        await loadQuestions()
    }
}


struct QuestionCardView: View {
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
                    .background(Color.accentBlue.opacity(0.2))
                    .foregroundColor(.accentBlue)
                    .cornerRadius(6)
                
                Spacer()
                
                Text("\(question.points) pts")
                    .font(.caption)
                    .foregroundColor(.dashboardTextSecondary)
            }
            
            Text(question.questionText)
                .font(.subheadline)
                .foregroundColor(.dashboardTextPrimary)
                .lineLimit(2)
            
            if let options = question.options {
                HStack {
                    Image(systemName: "list.bullet")
                        .foregroundColor(.dashboardTextSecondary)
                    Text("\(options.count) Options")
                        .foregroundColor(.dashboardTextSecondary)
                }
                .font(.caption)
            }
        }
        .padding()
        .background(Color.dashboardCard)
        .cornerRadius(16)
    }
}

// Add placeholder extension to View
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    CreateQuizView(course: Course(
        id: "1",
        organizationId: "org1",
        title: "iOS Development",
        courseDescription: "Learn iOS",
        level: .beginner,
        durationHours: 40,
        thumbnailURL: nil,
        isPublished: true, // Course still has isPublished
        createdById: "user1",
        assignedEducatorId: "educator1",
        createdAt: Date(),
        updatedAt: Date(),
        scheduledStartDate: nil,
        scheduledEndDate: nil,
        enrollmentDeadline: nil,
        maxEnrollments: nil,
        isVisibleInCatalog: true
    )) { }
}
