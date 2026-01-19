//
//  RecommendationModels.swift
//  LTMS
//
//  Created by Assistant on 17/01/26.
//

import Foundation

/// Represents a course recommendation with score and reasoning
struct CourseRecommendation: Identifiable {
    let id: String
    let course: Course
    let score: Double // 0.0 to 1.0
    let reason: String
    let recommendationType: RecommendationType
    
    enum RecommendationType: String {
        case collaborative = "Learners like you also took"
        case contentBased = "Based on your interests"
        case popular = "Trending in your organization"
        case nextInPath = "Next in your learning path"
        case skillGap = "Fill your skill gaps"
    }
}

/// Represents a personalized learning path
struct LearningPath: Identifiable {
    let id: String
    let title: String
    let description: String
    let courses: [Course]
    let estimatedDuration: Int // in hours
    let difficulty: CourseLevel
    let completionPercentage: Double
    
    var formattedDuration: String {
        if estimatedDuration < 24 {
            return "\(estimatedDuration) hours"
        } else {
            let days = estimatedDuration / 24
            return "\(days) days"
        }
    }
}

/// Tracks user preferences and learning history for recommendations
struct UserLearningProfile: Codable {
    var userId: String
    var enrolledCourseIds: [String]
    var completedCourseIds: [String]
    var preferredTopics: [String]
    var averageQuizScore: Double
    var totalTimeSpent: Int // in seconds
    var lastActiveDate: Date
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case enrolledCourseIds = "enrolled_course_ids"
        case completedCourseIds = "completed_course_ids"
        case preferredTopics = "preferred_topics"
        case averageQuizScore = "average_quiz_score"
        case totalTimeSpent = "total_time_spent"
        case lastActiveDate = "last_active_date"
    }
}

/// Activity log entry for detailed tracking
struct LearnerActivity: Codable, Identifiable {
    var id: String?
    var userId: String
    var activityType: ActivityType
    var courseId: String?
    var lessonId: String?
    var quizId: String?
    var description: String
    var timestamp: Date
    
    enum ActivityType: String, Codable {
        case enrollment = "enrollment"
        case lessonComplete = "lesson_complete"
        case quizComplete = "quiz_complete"
        case courseComplete = "course_complete"
        case login = "login"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case activityType = "activity_type"
        case courseId = "course_id"
        case lessonId = "lesson_id"
        case quizId = "quiz_id"
        case description
        case timestamp
    }
    
    var icon: String {
        switch activityType {
        case .enrollment:
            return "book.circle.fill"
        case .lessonComplete:
            return "checkmark.circle.fill"
        case .quizComplete:
            return "graduationcap.fill"
        case .courseComplete:
            return "star.circle.fill"
        case .login:
            return "person.circle.fill"
        }
    }
    
    var color: String {
        switch activityType {
        case .enrollment:
            return "blue"
        case .lessonComplete:
            return "green"
        case .quizComplete:
            return "purple"
        case .courseComplete:
            return "orange"
        case .login:
            return "gray"
        }
    }
}
