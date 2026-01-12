//
//  Module.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import Foundation

struct Module: Codable, Identifiable {
    var id: String?
    var courseId: String
    var title: String
    var moduleDescription: String
    var orderIndex: Int
    var milestones: [String]?
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case courseId = "course_id"
        case title
        case moduleDescription = "module_description"
        case orderIndex = "order_index"
        case milestones
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
