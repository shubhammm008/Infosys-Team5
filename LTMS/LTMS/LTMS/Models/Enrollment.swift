//
//  Enrollment.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import Foundation
import FirebaseFirestore

enum EnrollmentStatus: String, Codable, CaseIterable {
    case active
    case completed
    case dropped
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var color: String {
        switch self {
        case .active:
            return "blue"
        case .completed:
            return "green"
        case .dropped:
            return "gray"
        }
    }
}

struct Enrollment: Codable, Identifiable {
    @DocumentID var id: String?
    var learnerId: String
    var courseId: String
    var enrollmentDate: Date
    var completionPercentage: Double
    var status: EnrollmentStatus
    var lastAccessed: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case learnerId
        case courseId
        case enrollmentDate
        case completionPercentage
        case status
        case lastAccessed
    }
}
