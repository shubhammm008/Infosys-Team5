

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
        NavigationStack {
            Form {
                // Basic Info Section
                Section("Quiz Information") {
                    TextField("Quiz Title", text: $title)
                    
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    
                    if let lessonTitle = lesson?.title {
                        LabeledContent("For Lesson", value: lessonTitle)
                            .foregroundColor(.secondary)
                    }
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
                

                
                // Create Button
                Section {
                    Button {
                        Task { await createQuiz() }
                    } label: {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Create Quiz")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(title.isEmpty || isLoading)
                    .listRowBackground(
                        title.isEmpty ? Color.gray : Color.ltmsPrimary
                    )
                    .foregroundColor(.white)
                }
            }
            .navigationTitle(lesson != nil ? "Create Lesson Quiz" : "Create Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
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
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
                
                Text("Quiz Created!")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Now add questions to your quiz")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            Divider()
            
            // Questions List
            if questions.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "text.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No questions yet")
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                List {
                    ForEach(Array(questions.enumerated()), id: \.element.id) { index, question in
                        QuestionRowView(question: question, number: index + 1)
                    }
                }
            }
            
            // Bottom Buttons
            VStack(spacing: 12) {
                Button {
                    showAddQuestion = true
                } label: {
                    Label("Add Question", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.ltmsPrimary)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                if !questions.isEmpty {
                    Button {
                        onComplete()
                    } label: {
                        Text("Done")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                
                Button {
                    onComplete()
                } label: {
                    Text(questions.isEmpty ? "Skip for Now" : "")
                        .foregroundColor(.secondary)
                }
                .opacity(questions.isEmpty ? 1 : 0)
            }
            .padding()
        }
        .navigationTitle(quiz.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddQuestion) {
            if let quizId = quiz.id {
                AddQuestionView(assessmentId: quizId, orderIndex: questions.count + 1) {
                    Task { await loadQuestions() }
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
