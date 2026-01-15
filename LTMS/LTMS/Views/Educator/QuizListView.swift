//
//  QuizListView.swift
//  LTMS
//
//  Created for Quiz Feature - Educator View
//

import SwiftUI

/// View for educators to see all quizzes for a course or lesson
struct QuizListView: View {
    let course: Course
    let lesson: Lesson?  // Optional - if provided, shows quizzes for this lesson
    
    @StateObject private var authService = SupabaseAuthService.shared
    @Environment(\.dismiss) private var dismiss
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
        ZStack {
            Color.dashboardBg.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.dashboardTextPrimary)
                            .frame(width: 40, height: 40)
                            .background(Color.dashboardCard)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text(lesson != nil ? "Lesson Quizzes" : "Quizzes")
                        .font(.headline)
                        .foregroundColor(.dashboardTextPrimary)
                    
                    Spacer()
                    
                    Button {
                        showCreateQuiz = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.accentBlue)
                            .frame(width: 40, height: 40)
                            .background(Color.dashboardCard)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 16)
                
                // Content
                if isLoading {
                    Spacer()
                    ProgressView()
                        .tint(.accentBlue)
                        .scaleEffect(1.5)
                    Spacer()
                } else if quizzes.isEmpty {
                    emptyState
                } else {
                    quizList
                }
            }
        }
        .navigationBarHidden(true)
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
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "questionmark.circle")
                .font(.system(size: 70))
                .foregroundColor(.dashboardTextSecondary.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No Quizzes Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.dashboardTextPrimary)
                
                Text("Create a quiz to test your learners' knowledge")
                    .font(.subheadline)
                    .foregroundColor(.dashboardTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button {
                showCreateQuiz = true
            } label: {
                Text("Create Quiz")
                    .fontWeight(.bold)
                    .frame(maxWidth: 200)
                    .padding()
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
            
            Spacer()
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Quiz List
    
    private var quizList: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(quizzes) { quiz in
                    NavigationLink(destination: QuizDetailView(quiz: quiz, onUpdate: {
                        Task { await loadQuizzes() }
                    })) {
                        QuizRowView(quiz: quiz)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
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
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(quiz.title)
                    .font(.headline)
                    .foregroundColor(.dashboardTextPrimary)
                
                if let description = quiz.quizDescription, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.dashboardTextSecondary)
                        .lineLimit(1)
                }
                
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.accentBlue)
                        Text(quiz.passingScoreDisplay)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .foregroundColor(.accentBlue)
                        Text(quiz.timeLimitDisplay)
                    }
                }
                .font(.caption)
                .foregroundColor(.dashboardTextSecondary)
                .padding(.top, 4)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.dashboardTextSecondary)
        }
        .padding()
        .background(Color.dashboardCard)
        .cornerRadius(16)
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
    @Environment(\.dismiss) private var dismiss
    
    init(quiz: Quiz, onUpdate: @escaping () -> Void) {
        self.quiz = quiz
        self.onUpdate = onUpdate
        _currentQuiz = State(initialValue: quiz)
    }
    
    var body: some View {
        ZStack {
            Color.dashboardBg.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.dashboardTextPrimary)
                            .frame(width: 40, height: 40)
                            .background(Color.dashboardCard)
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text("Quiz Details")
                        .font(.headline)
                        .foregroundColor(.dashboardTextPrimary)
                    Spacer()
                    Button {
                        showEditQuiz = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.accentBlue)
                            .frame(width: 40, height: 40)
                            .background(Color.dashboardCard)
                            .clipShape(Circle())
                    }
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Quiz Info Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Quiz Information")
                                .font(.headline)
                                .foregroundColor(.dashboardTextPrimary)
                            
                            VStack(spacing: 0) {
                                infoRow(label: "Title", value: currentQuiz.title)
                                Divider().background(Color.white.opacity(0.1))
                                infoRow(label: "Passing Score", value: currentQuiz.passingScoreDisplay)
                                Divider().background(Color.white.opacity(0.1))
                                infoRow(label: "Time Limit", value: currentQuiz.timeLimitDisplay)
                                
                                if let description = currentQuiz.quizDescription, !description.isEmpty {
                                    Divider().background(Color.white.opacity(0.1))
                                    infoRow(label: "Description", value: description)
                                }
                            }
                            .background(Color.dashboardCard)
                            .cornerRadius(16)
                        }
                        
                        // Questions Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Questions (\(questions.count))")
                                    .font(.headline)
                                    .foregroundColor(.dashboardTextPrimary)
                                Spacer()
                                Button {
                                    showAddQuestion = true
                                } label: {
                                    Label("Add", systemImage: "plus")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.accentBlue)
                                }
                            }
                            
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .padding()
                            } else if questions.isEmpty {
                                Text("No questions added yet")
                                    .foregroundColor(.dashboardTextSecondary)
                                    .italic()
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .background(Color.dashboardCard)
                                    .cornerRadius(16)
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(Array(questions.enumerated()), id: \.element.id) { index, question in
                                        Button {
                                            questionToEdit = question
                                        } label: {
                                            HStack {
                                                QuestionRowView(question: question, number: index + 1)
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .font(.caption)
                                                    .foregroundColor(.dashboardTextSecondary)
                                            }
                                            .padding()
                                            .background(Color.dashboardCard)
                                            .cornerRadius(16)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
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
    
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.dashboardTextPrimary)
            Spacer()
            Text(value)
                .foregroundColor(.dashboardTextSecondary)
        }
        .padding()
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
                    .background(Color.accentBlue.opacity(0.2))
                    .foregroundColor(.accentBlue)
                    .cornerRadius(6)
                
                Text("\(question.points) pt\(question.points > 1 ? "s" : "")")
                    .font(.caption)
                    .foregroundColor(.dashboardTextSecondary)
            }
            
            Text(question.questionText)
                .font(.subheadline)
                .foregroundColor(.dashboardTextPrimary)
            
            if let options = question.options {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(options, id: \.self) { option in
                        HStack(spacing: 8) {
                            Image(systemName: option == question.correctAnswer ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(option == question.correctAnswer ? .green : .dashboardTextSecondary)
                                .font(.caption)
                            Text(option)
                                .font(.caption)
                                .foregroundColor(option == question.correctAnswer ? .green : .dashboardTextSecondary)
                        }
                    }
                }
                .padding(.leading, 8)
            }
        }
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
