//
//  Enrollment.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import Foundation
import Combine

enum EnrollmentStatus: String, Codable, CaseIterable {
    case active
    case completed
    case dropped
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var color: String {
        switch self {
        case .active:
            return "blue"
        case .completed:
            return "green"
        case .dropped:
            return "gray"
        }
    }
}

struct Enrollment: Codable, Identifiable {
    var id: String?
    var learnerId: String
    var courseId: String
    var enrollmentDate: Date
    var completionPercentage: Double
    var status: EnrollmentStatus
    var lastAccessed: Date?
    
    // Enrollment metadata
    var enrolledBy: String? // 'self' or admin userId
    var completedAt: Date?
    var certificateIssued: Bool
    
    // Supabase timestamps
    var createdAt: Date?
    var updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case learnerId = "learner_id"
        case courseId = "course_id"
        case enrollmentDate = "enrollment_date"
        case completionPercentage = "completion_percentage"
        case status
        case lastAccessed = "last_accessed"
        case enrolledBy = "enrolled_by"
        case completedAt = "completed_at"
        case certificateIssued = "certificate_issued"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
