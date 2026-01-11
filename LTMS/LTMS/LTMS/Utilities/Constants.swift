//
//  Constants.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import Foundation

struct FirebaseConstants {
    // Collection names
    static let organizations = "organizations"
    static let users = "users"
    static let courses = "courses"
    static let modules = "modules"
    static let lessons = "lessons"
    static let contents = "contents"
    static let enrollments = "enrollments"
    static let progress = "progress"
    
    // Storage paths
    static let profilePictures = "users"
    static let courseThumbnails = "organizations"
    static let courseContent = "content"
}

struct AppConstants {
    static let defaultOrganizationId = "5409038b-9dbc-4b63-b17d-a5f90932efc4"
    static let minimumPasswordLength = 6
}
