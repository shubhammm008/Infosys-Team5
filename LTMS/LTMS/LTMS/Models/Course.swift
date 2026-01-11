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
    }
}
