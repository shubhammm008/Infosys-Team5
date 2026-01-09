//
//  Lesson.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import Foundation

struct Lesson: Codable, Identifiable {
    var id: String
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
        case moduleId
        case title
        case lessonDescription
        case orderIndex
        case learningObjectives
        case prerequisites
        case createdAt
        case updatedAt
    }
}
