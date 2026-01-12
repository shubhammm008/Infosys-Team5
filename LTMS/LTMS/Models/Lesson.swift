//
//  Lesson.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import Foundation

struct Lesson: Codable, Identifiable {
    var id: String?
    var moduleId: String
    var title: String
    var lessonDescription: String
    var orderIndex: Int
    var learningObjectives: String?
    var prerequisites: String?
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case moduleId = "module_id"
        case title
        case lessonDescription = "lesson_description"
        case orderIndex = "order_index"
        case learningObjectives = "learning_objectives"
        case prerequisites
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
