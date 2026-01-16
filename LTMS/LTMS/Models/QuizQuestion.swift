//
//  QuizQuestion.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import Foundation

/// Represents a question in a quiz
/// Maps to the `assessment_questions` table in Supabase
struct QuizQuestion: Codable, Identifiable {
    var id: String?
    var assessmentId: String
    var questionText: String
    var questionType: String  // 'multiple_choice', 'true_false', 'short_answer', 'essay'
    var options: [String]?    // Array of option strings for MCQ
    var correctAnswer: String
    var points: Int
    var orderIndex: Int
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case assessmentId = "assessment_id"
        case questionText = "question_text"
        case questionType = "question_type"
        case options
        case correctAnswer = "correct_answer"
        case points
        case orderIndex = "order_index"
        case createdAt = "created_at"
    }
    
    /// Creates a new MCQ question with default values
    static func createMCQ(
        assessmentId: String,
        questionText: String,
        options: [String],
        correctAnswer: String,
        points: Int = 1,
        orderIndex: Int
    ) -> QuizQuestion {
        return QuizQuestion(
            id: nil,
            assessmentId: assessmentId,
            questionText: questionText,
            questionType: "multiple_choice",
            options: options,
            correctAnswer: correctAnswer,
            points: points,
            orderIndex: orderIndex,
            createdAt: Date()
        )
    }
    
    /// Creates a true/false question
    static func createTrueFalse(
        assessmentId: String,
        questionText: String,
        correctAnswer: Bool,
        points: Int = 1,
        orderIndex: Int
    ) -> QuizQuestion {
        return QuizQuestion(
            id: nil,
            assessmentId: assessmentId,
            questionText: questionText,
            questionType: "true_false",
            options: ["True", "False"],
            correctAnswer: correctAnswer ? "True" : "False",
            points: points,
            orderIndex: orderIndex,
            createdAt: Date()
        )
    }
    
    /// Check if a given answer is correct
    func isCorrect(_ answer: String) -> Bool {
        return answer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ==
               correctAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
