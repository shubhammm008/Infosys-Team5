//
//  User.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import Foundation

struct User: Codable, Identifiable {
    var id: String
    var organizationId: String?  // Optional - users can sign up without an organization
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
        case organizationId
        case email
        case role
        case firstName
        case lastName
        case profilePictureURL
        case isActive
        case createdAt
        case updatedAt
        case lastLogin
    }
}
