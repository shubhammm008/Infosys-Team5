//
//  Content.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import Foundation

enum ContentType: String, Codable, CaseIterable {
    case video
    case pdf
    case slide
    case text
    
    var displayName: String {
        switch self {
        case .video:
            return "Video"
        case .pdf:
            return "PDF Document"
        case .slide:
            return "Presentation"
        case .text:
            return "Text Content"
        }
    }
    
    var icon: String {
        switch self {
        case .video:
            return "play.rectangle.fill"
        case .pdf:
            return "doc.fill"
        case .slide:
            return "rectangle.stack.fill"
        case .text:
            return "text.alignleft"
        }
    }
}

struct Content: Codable, Identifiable {
    var id: String?
    var lessonId: String
    var contentType: ContentType
    var title: String
    var fileURL: String?
    var textContent: String?
    var metadata: String?
    var version: Int
    var createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case lessonId = "lesson_id"
        case contentType = "content_type"
        case title
        case fileURL = "file_url"
        case textContent = "text_content"
        case metadata
        case version
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
