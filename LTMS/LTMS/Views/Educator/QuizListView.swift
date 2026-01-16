//
//  QuizListView.swift
//  LTMS
//
//   - Educator View
//

import SwiftUI

/// View for educators to see all quizzes for a course or lesson
struct QuizListView: View {
    let course: Course
    let lesson: Lesson?  // Optional - if provided, shows quizzes for this lesson
    
    @StateObject private var authService = SupabaseAuthService.shared
    @State private var quizzes: [Quiz] = []
    @State private var isLoading = false
    @State private var showCreateQuiz = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    init(course: Course, lesson: Lesson? = nil) {
        self.course = course
        self.lesson = lesson
    }
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading quizzes...")
            } else if quizzes.isEmpty {
                emptyState
            } else {
                quizList
            }
        }
        .navigationTitle(lesson != nil ? "Lesson Quizzes" : "Quizzes")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCreateQuiz = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showCreateQuiz) {
            CreateQuizView(course: course, lesson: lesson) {
                Task { await loadQuizzes() }
            }
        }
        .task {
            await loadQuizzes()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Quizzes Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create a quiz to test your learners' knowledge")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                showCreateQuiz = true
            } label: {
                Label("Create Quiz", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: 200)
                    .background(Color.ltmsPrimary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
    
    // MARK: - Quiz List
    
    private var quizList: some View {
        List {
            ForEach(quizzes) { quiz in
                NavigationLink(destination: QuizDetailView(quiz: quiz, onUpdate: {
                    Task { await loadQuizzes() }
                })) {
                    QuizRowView(quiz: quiz)
                }
            }
            .onDelete(perform: deleteQuizzes)
        }
        .refreshable {
            await loadQuizzes()
        }
    }
    
    // MARK: - Actions
    
    private func loadQuizzes() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            if let lessonId = lesson?.id {
                // Fetch quizzes for specific lesson
                quizzes = try await QuizService.shared.fetchQuizzesByLesson(lessonId: lessonId)
            } else if let courseId = course.id {
                // Fetch all course-level quizzes (those without lessonId)
                quizzes = try await QuizService.shared.fetchQuizzesByCourse(courseId: courseId)
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func deleteQuizzes(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let quiz = quizzes[index]
                if let id = quiz.id {
                    do {
                        try await QuizService.shared.deleteQuiz(id: id)
                        quizzes.remove(at: index)
                    } catch {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            }
        }
    }
}

// MARK: - Quiz Row View

struct QuizRowView: View {
    let quiz: Quiz
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(quiz.title)
                    .font(.headline)
                
                Spacer()
            }
            
            if let description = quiz.quizDescription, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack(spacing: 16) {
                Label(quiz.passingScoreDisplay, systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Label(quiz.timeLimitDisplay, systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Quiz Detail View (for editing)

struct QuizDetailView: View {
    let quiz: Quiz
    let onUpdate: () -> Void
    
    @State private var currentQuiz: Quiz
    @State private var questions: [QuizQuestion] = []
    @State private var isLoading = false
    @State private var showAddQuestion = false
    @State private var showEditQuiz = false
    @State private var questionToEdit: QuizQuestion?
    @State private var showError = false
    @State private var errorMessage = ""
    
    init(quiz: Quiz, onUpdate: @escaping () -> Void) {
        self.quiz = quiz
        self.onUpdate = onUpdate
        _currentQuiz = State(initialValue: quiz)
    }
    
    var body: some View {
        List {
            // Quiz Info Section
            Section("Quiz Information") {
                LabeledContent("Title", value: currentQuiz.title)
                LabeledContent("Passing Score", value: currentQuiz.passingScoreDisplay)
                LabeledContent("Time Limit", value: currentQuiz.timeLimitDisplay)
                
                if let description = currentQuiz.quizDescription, !description.isEmpty {
                    LabeledContent("Description", value: description)
                }
            }
            
            // Questions Section
            Section {
                if isLoading {
                    ProgressView()
                } else if questions.isEmpty {
                    Text("No questions added yet")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(Array(questions.enumerated()), id: \.element.id) { index, question in
                        Button {
                            questionToEdit = question
                        } label: {
                            HStack {
                                QuestionRowView(question: question, number: index + 1)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deleteQuestions)
                }
            } header: {
                HStack {
                    Text("Questions (\(questions.count))")
                    Spacer()
                    Button {
                        showAddQuestion = true
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                }
            }
        }
        .navigationTitle("Quiz Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showEditQuiz = true
                } label: {
                    Image(systemName: "pencil")
                }
            }
        }
        .sheet(isPresented: $showEditQuiz) {
            EditQuizView(quiz: currentQuiz) {
                // Reload the quiz after editing
                Task {
                    if let quizId = quiz.id {
                        do {
                            currentQuiz = try await QuizService.shared.fetchQuiz(id: quizId)
                            onUpdate()
                        } catch {
                            print("Error reloading quiz: \(error)")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showAddQuestion) {
            if let quizId = quiz.id {
                AddQuestionView(assessmentId: quizId, orderIndex: questions.count + 1) {
                    Task { await loadQuestions() }
                }
            }
        }
        .sheet(item: $questionToEdit) { question in
            EditQuestionView(question: question) {
                Task { await loadQuestions() }
            }
        }
        .task {
            await loadQuestions()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func loadQuestions() async {
        guard let quizId = quiz.id else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            questions = try await QuizService.shared.fetchQuestionsByQuiz(quizId: quizId)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func deleteQuestions(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let question = questions[index]
                if let id = question.id {
                    do {
                        try await QuizService.shared.deleteQuestion(id: id)
                        questions.remove(at: index)
                    } catch {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            }
        }
    }
}

// MARK: - Question Row View

struct QuestionRowView: View {
    let question: QuizQuestion
    let number: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Q\(number)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.ltmsPrimary.opacity(0.2))
                    .foregroundColor(.ltmsPrimary)
                    .cornerRadius(6)
                
                Text("\(question.points) pt\(question.points > 1 ? "s" : "")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(question.questionText)
                .font(.subheadline)
            
            if let options = question.options {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(options, id: \.self) { option in
                        HStack(spacing: 8) {
                            Image(systemName: option == question.correctAnswer ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(option == question.correctAnswer ? .green : .secondary)
                                .font(.caption)
                            Text(option)
                                .font(.caption)
                                .foregroundColor(option == question.correctAnswer ? .green : .secondary)
                        }
                    }
                }
                .padding(.leading, 8)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        QuizListView(course: Course(
            id: "1",
            organizationId: "org1",
            title: "iOS Development",
            courseDescription: "Learn iOS",
            level: .beginner,
            durationHours: 40,
            thumbnailURL: nil,
            isPublished: true,
            createdById: "user1",
            assignedEducatorId: "educator1",
            createdAt: Date(),
            updatedAt: Date(),
            scheduledStartDate: nil,
            scheduledEndDate: nil,
            enrollmentDeadline: nil,
            maxEnrollments: nil,
            isVisibleInCatalog: true
        ))
    }
}
