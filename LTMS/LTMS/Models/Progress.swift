//
//  Progress.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import Foundation

struct Progress: Codable, Identifiable {
    var id: String?
    var enrollmentId: String
    var lessonId: String
    var isCompleted: Bool
    var timeSpentSeconds: Int
    var lastPosition: String?
    var completedAt: Date?
    var updatedAt: Date
    
    var timeSpentFormatted: String {
        let hours = timeSpentSeconds / 3600
        let minutes = (timeSpentSeconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case enrollmentId = "enrollment_id"
        case lessonId = "lesson_id"
        case isCompleted = "is_completed"
        case timeSpentSeconds = "time_spent_seconds"
        case lastPosition = "last_position"
        case completedAt = "completed_at"
        case updatedAt = "updated_at"
    }
}
