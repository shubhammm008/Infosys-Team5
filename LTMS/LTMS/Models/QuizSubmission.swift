//
//  QuizSubmission.swift
//  LTMS
//
//  Created for Quiz Feature
//

import Foundation

/// Represents a learner's submission for a quiz
/// Maps to the `assessment_submissions` table in Supabase
struct QuizSubmission: Codable, Identifiable {
    var id: String?
    var assessmentId: String
    var userId: String
    var submittedAt: Date
    var score: Double?
    var passed: Bool?
    var answers: [String: String]?  // questionId -> selected answer
    var feedback: String?
    var gradedBy: String?
    var gradedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case assessmentId = "assessment_id"
        case userId = "user_id"
        case submittedAt = "submitted_at"
        case score
        case passed
        case answers
        case feedback
        case gradedBy = "graded_by"
        case gradedAt = "graded_at"
    }
    
    /// Creates a new submission for auto-grading
    static func create(
        assessmentId: String,
        userId: String,
        answers: [String: String]
    ) -> QuizSubmission {
        return QuizSubmission(
            id: nil,
            assessmentId: assessmentId,
            userId: userId,
            submittedAt: Date(),
            score: nil,
            passed: nil,
            answers: answers,
            feedback: nil,
            gradedBy: nil,
            gradedAt: nil
        )
    }
    
    /// Computed property for score display
    var scoreDisplay: String {
        guard let score = score else { return "Not graded" }
        return String(format: "%.1f%%", score)
    }
    
    /// Computed property for status display
    var statusDisplay: String {
        guard let passed = passed else { return "Pending" }
        return passed ? "Passed ✓" : "Failed ✗"
    }
    
    /// Computed property for status color name
    var statusColorName: String {
        guard let passed = passed else { return "gray" }
        return passed ? "green" : "red"
    }
}

/// Helper struct for encoding answers to JSONB
struct QuizAnswers: Codable {
    var answers: [String: String]
    
    init(_ answers: [String: String]) {
        self.answers = answers
    }
}
