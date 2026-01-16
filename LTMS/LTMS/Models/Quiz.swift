//
//  Quiz.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import Foundation

/// Represents a quiz/assessment associated with a course or lesson
/// Maps to the `assessments` table in Supabase
struct Quiz: Codable, Identifiable {
    var id: String?
    var courseId: String
    var lessonId: String?  // Optional - if set, quiz is for a specific lesson
    var title: String
    var quizDescription: String?
    var type: String  // 'quiz', 'assignment', 'exam'
    var passingScore: Double?
    var timeLimitMinutes: Int?
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case courseId = "course_id"
        case lessonId = "lesson_id"
        case title
        case quizDescription = "description"
        case type
        case passingScore = "passing_score"
        case timeLimitMinutes = "time_limit_minutes"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    /// Creates a new quiz with default values
    static func create(
        courseId: String,
        lessonId: String? = nil,
        title: String,
        description: String? = nil,
        passingScore: Double = 70.0,
        timeLimitMinutes: Int? = nil
    ) -> Quiz {
        return Quiz(
            id: nil,
            courseId: courseId,
            lessonId: lessonId,
            title: title,
            quizDescription: description,
            type: "quiz",
            passingScore: passingScore,
            timeLimitMinutes: timeLimitMinutes,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    /// Computed property for display-friendly time limit
    var timeLimitDisplay: String {
        guard let minutes = timeLimitMinutes else { return "No time limit" }
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours) hour\(hours > 1 ? "s" : "")"
            }
            return "\(hours)h \(remainingMinutes)m"
        }
        return "\(minutes) minutes"
    }
    
    /// Computed property for passing score display
    var passingScoreDisplay: String {
        guard let score = passingScore else { return "No passing score" }
        return "\(Int(score))%"
    }
}
