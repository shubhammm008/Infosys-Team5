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
    var id: String
    var organizationId: String?  // Optional - courses can be created without an organization
    var title: String
    var courseDescription: String
    var level: CourseLevel
    var durationHours: Int
    var thumbnailURL: String?
    var isPublished: Bool
    var createdById: String
    var assignedEducatorId: String?
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case organizationId
        case title
        case courseDescription
        case level
        case durationHours
        case thumbnailURL
        case isPublished
        case createdById
        case assignedEducatorId
        case createdAt
        case updatedAt
    }
}
