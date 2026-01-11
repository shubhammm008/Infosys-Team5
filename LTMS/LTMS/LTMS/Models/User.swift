//
//  User.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import Foundation

struct User: Codable, Identifiable {
    var id: String?
    var organizationId: String
    var email: String
    var role: UserRole
    var firstName: String
    var lastName: String
    var profilePictureURL: String?
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date
    var lastLogin: Date?
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case organizationId = "organization_id"
        case email
        case role
        case firstName = "first_name"
        case lastName = "last_name"
        case profilePictureURL = "profile_picture_url"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastLogin = "last_login"
    }
}
