//
//  Course.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import Foundation

enum CourseLevel: String, Codable, CaseIterable {
    case beginner
    case intermediate
    case advanced
    
    var displayName: String {
        rawValue.capitalized
    }
}

struct Course: Codable, Identifiable {
    var id: String?
    var organizationId: String
    var title: String
    var courseDescription: String
    var level: CourseLevel
    var durationHours: Int
    var thumbnailURL: String?
    var isPublished: Bool
    var createdById: String
    var assignedEducatorId: String?
    var prerequisites: [String]?
    var learningObjectives: [String]?
    var createdAt: Date
    var updatedAt: Date
    
    // Scheduling fields
    var scheduledStartDate: Date?
    var scheduledEndDate: Date?
    var enrollmentDeadline: Date?
    
    // Enrollment management
    var maxEnrollments: Int?
    var isVisibleInCatalog: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case organizationId = "organization_id"
        case title
        case courseDescription = "description"
        case level = "difficulty_level"
        case durationHours = "duration_hours"
        case thumbnailURL = "thumbnail_url"
        case isPublished = "is_published"
        case createdById = "created_by"
        case assignedEducatorId = "assigned_educator_id"
        case prerequisites
        case learningObjectives = "learning_objectives"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case scheduledStartDate = "scheduled_start_date"
        case scheduledEndDate = "scheduled_end_date"
        case enrollmentDeadline = "enrollment_deadline"
        case maxEnrollments = "max_enrollments"
        case isVisibleInCatalog = "is_visible_in_catalog"
    }
    
    // Computed properties for scheduling status
    var isScheduled: Bool {
        scheduledStartDate != nil || scheduledEndDate != nil
    }
    
    var isCurrentlyAvailable: Bool {
        guard isPublished else { return false }
        let now = Date()
        
        if let start = scheduledStartDate, start > now {
            return false
        }
        if let end = scheduledEndDate, end < now {
            return false
        }
        return true
    }
    
    var enrollmentStatus: String {
        guard let deadline = enrollmentDeadline else { return "Open" }
        return deadline > Date() ? "Open" : "Closed"
    }
}
