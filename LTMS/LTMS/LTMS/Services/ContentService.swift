//
//  ContentService.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import Foundation
import Combine
import FirebaseStorage

@MainActor
class ContentService: ObservableObject {
    static let shared = ContentService()
    // private let storage = Storage.storage() // DISABLED - Migrated to Supabase
    // private let db = Firestore.firestore() // Disabled for Supabase migration
    
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    
    private init() {}
    
    // MARK: - Content Operations
    
    func createContent(_ content: Content) async throws -> String {
        return try await FirebaseService.shared.create(content, in: FirebaseConstants.contents)
    }
    
    func fetchContentsByLesson(lessonId: String) async throws -> [Content] {
        return try await FirebaseService.shared.query(
            from: FirebaseConstants.contents,
            where: "lessonId",
            isEqualTo: lessonId
        )
    }
    
    func updateContent(_ content: Content) async throws {
        guard let id = content.id else { return }
        try await FirebaseService.shared.update(content, id: id, in: FirebaseConstants.contents)
    }
    
    func deleteContent(id: String) async throws {
        try await FirebaseService.shared.delete(id: id, from: FirebaseConstants.contents)
    }
    
    // MARK: - File Upload
    // ALL METHODS DISABLED - Need to migrate to Supabase Storage
    
    func uploadFile(data: Data, path: String, contentType: String) async throws -> String {
        fatalError("File upload disabled - migrate to Supabase Storage")
    }
    
    func uploadVideo(data: Data, organizationId: String, courseId: String, contentId: String) async throws -> String {
        fatalError("File upload disabled - migrate to Supabase Storage")
    }
    
    func uploadPDF(data: Data, organizationId: String, courseId: String, contentId: String) async throws -> String {
        fatalError("File upload disabled - migrate to Supabase Storage")
    }
    
    func uploadThumbnail(data: Data, organizationId: String, courseId: String) async throws -> String {
        fatalError("File upload disabled - migrate to Supabase Storage")
    }
    
    // MARK: - Enrollment Operations
    
    func enrollInCourse(learnerId: String, courseId: String) async throws -> String {
        let enrollment = Enrollment(
            id: nil,
            learnerId: learnerId,
            courseId: courseId,
            enrollmentDate: Date(),
            completionPercentage: 0.0,
            status: .active,
            lastAccessed: Date()
        )
        return try await FirebaseService.shared.create(enrollment, in: FirebaseConstants.enrollments)
    }
    
    func fetchEnrollmentsByLearner(learnerId: String) async throws -> [Enrollment] {
        return try await FirebaseService.shared.query(
            from: FirebaseConstants.enrollments,
            where: "learnerId",
            isEqualTo: learnerId
        )
    }
    
    func fetchEnrollmentsByCourse(courseId: String) async throws -> [Enrollment] {
        return try await FirebaseService.shared.query(
            from: FirebaseConstants.enrollments,
            where: "courseId",
            isEqualTo: courseId
        )
    }
    
    func updateEnrollment(_ enrollment: Enrollment) async throws {
        guard let id = enrollment.id else { return }
        try await FirebaseService.shared.update(enrollment, id: id, in: FirebaseConstants.enrollments)
    }
    
    // MARK: - Progress Operations
    
    func updateProgress(_ progress: Progress) async throws {
        if let id = progress.id {
            try await FirebaseService.shared.update(progress, id: id, in: FirebaseConstants.progress)
        } else {
            _ = try await FirebaseService.shared.create(progress, in: FirebaseConstants.progress)
        }
    }
    
    func fetchProgressByEnrollment(enrollmentId: String) async throws -> [Progress] {
        return try await FirebaseService.shared.query(
            from: FirebaseConstants.progress,
            where: "enrollmentId",
            isEqualTo: enrollmentId
        )
    }
}
