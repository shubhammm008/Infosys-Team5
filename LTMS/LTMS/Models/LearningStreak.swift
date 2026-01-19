//
//  LearningStreak.swift
//  LTMS
//
//  Created by Assistant on 17/01/26.
//

import Foundation

/// Model for tracking learner's learning streaks
struct LearningStreak: Codable, Identifiable {
    var id: String?
    var userId: String
    var currentStreak: Int
    var longestStreak: Int
    var lastActivityDate: Date
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case lastActivityDate = "last_activity_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    /// Check if streak is still active (activity within last 24 hours)
    var isActive: Bool {
        let daysSinceLastActivity = Calendar.current.dateComponents([.day], from: lastActivityDate, to: Date()).day ?? 0
        return daysSinceLastActivity <= 1
    }
    
    /// Get streak status message
    var statusMessage: String {
        if currentStreak == 0 {
            return "Start your learning streak today!"
        } else if isActive {
            return "\(currentStreak) day streak! Keep it up!"
        } else {
            return "Streak ended. Start a new one!"
        }
    }
}
