//
//  Organization.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import Foundation
import FirebaseFirestore

struct Organization: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var organizationDescription: String
    var logoURL: String?
    var createdAt: Date
    var updatedAt: Date
    var isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case organizationDescription
        case logoURL
        case createdAt
        case updatedAt
        case isActive
    }
}
