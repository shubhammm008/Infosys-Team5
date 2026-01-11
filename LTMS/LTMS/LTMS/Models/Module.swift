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
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case courseId
        case title
        case moduleDescription
        case orderIndex
        case createdAt
        case updatedAt
    }
}
