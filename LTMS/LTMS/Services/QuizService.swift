//
//  QuizService.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import Foundation
import Combine
import Supabase

/// Service for managing quizzes, questions, and submissions
@MainActor
class QuizService: ObservableObject {
    static let shared = QuizService()
    
    @Published var isLoading = false
    
    private let supabase = SupabaseService.shared
    
    private init() {}
    
    // MARK: - Quiz CRUD Operations
    
    /// Create a new quiz
    func createQuiz(_ quiz: Quiz) async throws -> Quiz {
        print("📝 Creating quiz: \(quiz.title)")
        let created: Quiz = try await supabase.create(quiz, in: SupabaseConstants.assessments)
        print("✅ Quiz created with ID: \(created.id ?? "unknown")")
        return created
    }
    
    /// Fetch all quizzes for a course
    func fetchQuizzesByCourse(courseId: String) async throws -> [Quiz] {
        print("📚 Fetching quizzes for course: \(courseId)")
        let quizzes: [Quiz] = try await supabase.queryMultiple(
            from: SupabaseConstants.assessments,
            filters: [
                ("course_id", courseId),
                ("type", "quiz")
            ]
        )
        print("✅ Found \(quizzes.count) quizzes")
        return quizzes
    }
    
    /// Fetch all quizzes for a specific lesson
    func fetchQuizzesByLesson(lessonId: String) async throws -> [Quiz] {
        print("📚 Fetching quizzes for lesson: \(lessonId)")
        let quizzes: [Quiz] = try await supabase.queryMultiple(
            from: SupabaseConstants.assessments,
            filters: [
                ("lesson_id", lessonId),
                ("type", "quiz")
            ]
        )
        print("✅ Found \(quizzes.count) quizzes for lesson")
        return quizzes
    }
    
    /// Fetch a single quiz by ID
    func fetchQuiz(id: String) async throws -> Quiz {
        return try await supabase.fetch(id: id, from: SupabaseConstants.assessments)
    }
    
    /// Update a quiz
    func updateQuiz(_ quiz: Quiz) async throws -> Quiz {
        guard let id = quiz.id else {
            throw QuizError.missingId
        }
        return try await supabase.update(quiz, id: id, in: SupabaseConstants.assessments)
    }
    
    /// Delete a quiz (also deletes related questions via cascade)
    func deleteQuiz(id: String) async throws {
        print("🗑️ Deleting quiz: \(id)")
        try await supabase.delete(id: id, from: SupabaseConstants.assessments)
        print("✅ Quiz deleted")
    }
    
    // MARK: - Question CRUD Operations
    
    /// Add a question to a quiz
    func createQuestion(_ question: QuizQuestion) async throws -> QuizQuestion {
        print("📝 Adding question to quiz: \(question.assessmentId)")
        let created: QuizQuestion = try await supabase.create(question, in: SupabaseConstants.assessmentQuestions)
        print("✅ Question created with ID: \(created.id ?? "unknown")")
        return created
    }
    
    /// Fetch all questions for a quiz
    func fetchQuestionsByQuiz(quizId: String) async throws -> [QuizQuestion] {
        print("📚 Fetching questions for quiz: \(quizId)")
        
        // Use custom decoder for the options array
        let response = try await supabase.client
            .from(SupabaseConstants.assessmentQuestions)
            .select()
            .eq("assessment_id", value: quizId)
            .order("order_index", ascending: true)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let questions = try decoder.decode([QuizQuestion].self, from: response.data)
        
        print("✅ Found \(questions.count) questions")
        return questions
    }
    
    /// Update a question
    func updateQuestion(_ question: QuizQuestion) async throws -> QuizQuestion {
        guard let id = question.id else {
            throw QuizError.missingId
        }
        return try await supabase.update(question, id: id, in: SupabaseConstants.assessmentQuestions)
    }
    
    /// Delete a question
    func deleteQuestion(id: String) async throws {
        print("🗑️ Deleting question: \(id)")
        try await supabase.delete(id: id, from: SupabaseConstants.assessmentQuestions)
        print("✅ Question deleted")
    }
    
    // MARK: - Submission Operations
    
    /// Submit quiz answers and auto-grade
    func submitQuiz(
        assessmentId: String,
        userId: String,
        answers: [String: String]  // questionId -> selected answer
    ) async throws -> QuizSubmission {
        print("📝 Submitting quiz: \(assessmentId) by user: \(userId)")
        
        // Fetch quiz details for passing score
        let quiz = try await fetchQuiz(id: assessmentId)
        
        // Fetch all questions either way for grading
        let questions = try await fetchQuestionsByQuiz(quizId: assessmentId)
        
        guard !questions.isEmpty else {
            throw QuizError.noQuestions
        }
        
        // Calculate score
        var correctCount = 0
        var totalPoints = 0
        var earnedPoints = 0
        
        for question in questions {
            guard let questionId = question.id else { continue }
            totalPoints += question.points
            
            if let userAnswer = answers[questionId] {
                if question.isCorrect(userAnswer) {
                    correctCount += 1
                    earnedPoints += question.points
                }
            }
        }
        
        let scorePercentage = totalPoints > 0 ? (Double(earnedPoints) / Double(totalPoints)) * 100 : 0
        let passed = quiz.passingScore != nil ? scorePercentage >= quiz.passingScore! : true
        
        print("📊 Score: \(earnedPoints)/\(totalPoints) = \(scorePercentage)% | Passed: \(passed)")
        
        // Generate AI-powered feedback
        let aiFeedback = await AIFeedbackService.shared.generateQuizFeedback(
            score: scorePercentage,
            passed: passed,
            courseTitle: quiz.courseId,
            quizTitle: quiz.title
        )
        
        // Create submission
        var submission = QuizSubmission.create(
            assessmentId: assessmentId,
            userId: userId,
            answers: answers
        )
        submission.score = scorePercentage
        submission.passed = passed
        submission.gradedAt = Date()
        submission.feedback = aiFeedback
        
        // Save to database
        let saved: QuizSubmission = try await supabase.create(submission, in: SupabaseConstants.assessmentSubmissions)
        print("✅ Submission saved with ID: \(saved.id ?? "unknown")")
        
        // Log quiz completion activity
        do {
            try await ProgressAnalyticsService.shared.logActivity(
                userId: userId,
                activityType: .quizComplete,
                description: "Completed quiz: \(quiz.title) - Score: \(Int(scorePercentage))%",
                courseId: quiz.courseId,
                quizId: assessmentId
            )
        } catch {
            print("⚠️ Failed to log quiz completion activity: \(error)")
        }
        
        return saved
    }
    
    /// Fetch all submissions for a user
    func fetchSubmissionsByUser(userId: String) async throws -> [QuizSubmission] {
        return try await supabase.query(
            from: SupabaseConstants.assessmentSubmissions,
            where: "user_id",
            equals: userId
        )
    }
    
    /// Fetch all submissions for a quiz (for educators)
    func fetchSubmissionsForQuiz(assessmentId: String) async throws -> [QuizSubmission] {
        return try await supabase.query(
            from: SupabaseConstants.assessmentSubmissions,
            where: "assessment_id",
            equals: assessmentId
        )
    }
    
    /// Check if user has already attempted a quiz
    func hasUserAttempted(userId: String, assessmentId: String) async throws -> Bool {
        let submissions: [QuizSubmission] = try await supabase.queryMultiple(
            from: SupabaseConstants.assessmentSubmissions,
            filters: [
                ("user_id", userId),
                ("assessment_id", assessmentId)
            ]
        )
        return !submissions.isEmpty
    }
    
    /// Fetch user's submission for a specific quiz
    func fetchUserSubmission(userId: String, assessmentId: String) async throws -> QuizSubmission? {
        let submissions: [QuizSubmission] = try await supabase.queryMultiple(
            from: SupabaseConstants.assessmentSubmissions,
            filters: [
                ("user_id", userId),
                ("assessment_id", assessmentId)
            ]
        )
        return submissions.first
    }
    
    // MARK: - Helper Methods
    
    /// Generate feedback message based on score
    private func generateFeedback(correctCount: Int, totalCount: Int, passed: Bool) -> String {
        let percentage = totalCount > 0 ? (Double(correctCount) / Double(totalCount)) * 100 : 0
        
        if passed {
            if percentage >= 90 {
                return "Excellent work! You've mastered this material."
            } else if percentage >= 80 {
                return "Great job! You have a solid understanding."
            } else {
                return "Good work! You passed the quiz."
            }
        } else {
            if percentage >= 50 {
                return "You're close! Review the material and try again."
            } else {
                return "Keep studying! Review the course content before retrying."
            }
        }
    }
}

// MARK: - Quiz Errors

enum QuizError: LocalizedError {
    case missingId
    case noQuestions
    case alreadyAttempted
    case quizNotFound
    
    var errorDescription: String? {
        switch self {
        case .missingId:
            return "Quiz or question ID is missing"
        case .noQuestions:
            return "This quiz has no questions"
        case .alreadyAttempted:
            return "You have already attempted this quiz"
        case .quizNotFound:
            return "Quiz not found"
        }
    }
}
