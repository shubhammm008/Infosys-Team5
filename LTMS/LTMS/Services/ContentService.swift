//
//  ContentService.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import Foundation
import Combine
import Supabase

@MainActor
class ContentService: ObservableObject {
    static let shared = ContentService()
    private let supabase = SupabaseService.shared.client
    
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    
    private init() {}
    
    // MARK: - Content Operations
    
    func createContent(_ content: Content) async throws -> String {
        return try await SupabaseService.shared.create(content, in: FirebaseConstants.contents)
    }
    
    func fetchContentsByLesson(lessonId: String) async throws -> [Content] {
        return try await SupabaseService.shared.query(
            from: FirebaseConstants.contents,
            where: "lessonId",
            isEqualTo: lessonId
        )
    }
    
    func updateContent(_ content: Content) async throws {
        try await SupabaseService.shared.update(content, id: content.id, in: FirebaseConstants.contents)
    }
    
    func deleteContent(id: String) async throws {
        try await SupabaseService.shared.delete(id: id, from: FirebaseConstants.contents)
    }
    
    // MARK: - File Upload
    
    func uploadFile(data: Data, bucket: String, path: String, contentType: String) async throws -> String {
        isUploading = true
        uploadProgress = 0.0
        defer { isUploading = false }

        // Upload to Supabase Storage
        let storage = supabase.storage
        _ = try await storage.from(bucket).upload(
            path: path,
            file: data,
            options: FileOptions(contentType: contentType)
        )

        // Get public URL
        let publicURL = try storage.from(bucket).getPublicURL(path: path)
        return publicURL.absoluteString
    }
    
    func uploadVideo(data: Data, organizationId: String, courseId: String, contentId: String) async throws -> String {
        let path = "\(organizationId)/courses/\(courseId)/content/videos/\(contentId).mp4"
        return try await uploadFile(data: data, bucket: SupabaseConfig.Storage.courseVideos, path: path, contentType: "video/mp4")
    }

    func uploadPDF(data: Data, organizationId: String, courseId: String, contentId: String) async throws -> String {
        let path = "\(organizationId)/courses/\(courseId)/content/pdfs/\(contentId).pdf"
        return try await uploadFile(data: data, bucket: SupabaseConfig.Storage.coursePDFs, path: path, contentType: "application/pdf")
    }

    func uploadThumbnail(data: Data, organizationId: String, courseId: String) async throws -> String {
        let path = "\(organizationId)/courses/\(courseId)/thumbnails/thumbnail.jpg"
        return try await uploadFile(data: data, bucket: SupabaseConfig.Storage.courseThumbnails, path: path, contentType: "image/jpeg")
    }
    
    // MARK: - Enrollment Operations
    
    func enrollInCourse(learnerId: String, courseId: String) async throws -> String {
        let enrollment = Enrollment(
            id: UUID().uuidString,
            learnerId: learnerId,
            courseId: courseId,
            enrollmentDate: Date(),
            completionPercentage: 0.0,
            status: .active,
            lastAccessed: Date()
        )
        return try await SupabaseService.shared.create(enrollment, in: FirebaseConstants.enrollments)
    }
    
    func fetchEnrollmentsByLearner(learnerId: String) async throws -> [Enrollment] {
        return try await SupabaseService.shared.query(
            from: FirebaseConstants.enrollments,
            where: "learnerId",
            isEqualTo: learnerId
        )
    }
    
    func fetchEnrollmentsByCourse(courseId: String) async throws -> [Enrollment] {
        return try await SupabaseService.shared.query(
            from: FirebaseConstants.enrollments,
            where: "courseId",
            isEqualTo: courseId
        )
    }
    
    func updateEnrollment(_ enrollment: Enrollment) async throws {
        try await SupabaseService.shared.update(enrollment, id: enrollment.id, in: FirebaseConstants.enrollments)
    }
    
    // MARK: - Progress Operations
    
    func updateProgress(_ progress: Progress) async throws {
        if !progress.id.isEmpty {
            try await SupabaseService.shared.update(progress, id: progress.id, in: FirebaseConstants.progress)
        } else {
            _ = try await SupabaseService.shared.create(progress, in: FirebaseConstants.progress)
        }
    }
    
    func fetchProgressByEnrollment(enrollmentId: String) async throws -> [Progress] {
        return try await SupabaseService.shared.query(
            from: FirebaseConstants.progress,
            where: "enrollmentId",
            isEqualTo: enrollmentId
        )
    }
}
