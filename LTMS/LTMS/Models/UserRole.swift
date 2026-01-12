//
//  UserRole.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import Foundation

enum UserRole: String, Codable, CaseIterable {
    case admin
    case educator
    case learner
    
    var displayName: String {
        switch self {
        case .admin:
            return "Admin"
        case .educator:
            return "Educator"
        case .learner:
            return "Learner"
        }
    }
}
