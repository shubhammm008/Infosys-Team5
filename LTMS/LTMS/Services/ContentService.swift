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
    
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    
    private init() {}
    
    // MARK: - Content Operations (Supabase)
    
    func createContent(_ content: Content) async throws -> Content {
        return try await SupabaseService.shared.create(content, in: SupabaseConstants.contents)
    }
    
    func fetchContentsByLesson(lessonId: String) async throws -> [Content] {
        return try await SupabaseService.shared.query(
            from: SupabaseConstants.contents,
            where: "lesson_id",
            equals: lessonId
        )
    }
    
    func updateContent(_ content: Content) async throws {
        guard let id = content.id else { return }
        let _: Content = try await SupabaseService.shared.update(content, id: id, in: SupabaseConstants.contents)
    }
    
    func deleteContent(id: String) async throws {
        try await SupabaseService.shared.delete(id: id, from: SupabaseConstants.contents)
    }
    
    // MARK: - File Upload (Supabase Storage)
    
    func uploadFile(data: Data, path: String, contentType: String) async throws -> String {
        isUploading = true
        uploadProgress = 0.0
        defer { isUploading = false }
        
        let bucket: String
        switch contentType {
        case _ where contentType.contains("video"):
            bucket = StorageBuckets.courseVideos
        case _ where contentType.contains("pdf"):
            bucket = StorageBuckets.coursePDFs
        default:
            bucket = StorageBuckets.courseSlides
        }
        
        let url = try await SupabaseService.shared.uploadFile(
            data: data,
            bucket: bucket,
            path: path,
            contentType: contentType
        ) { [weak self] progress in
            Task { @MainActor in
                self?.uploadProgress = progress
            }
        }
        
        uploadProgress = 1.0
        return url
    }
    
    func uploadVideo(data: Data, organizationId: String, courseId: String, fileName: String) async throws -> String {
        isUploading = true
        uploadProgress = 0.0
        defer { isUploading = false }
        
        let url = try await SupabaseService.shared.uploadVideo(
            data: data,
            organizationId: organizationId,
            courseId: courseId,
            fileName: fileName
        ) { [weak self] progress in
            Task { @MainActor in
                self?.uploadProgress = progress
            }
        }
        
        uploadProgress = 1.0
        return url
    }
    
    func uploadPDF(data: Data, organizationId: String, courseId: String, fileName: String) async throws -> String {
        isUploading = true
        uploadProgress = 0.0
        defer { isUploading = false }
        
        let url = try await SupabaseService.shared.uploadPDF(
            data: data,
            organizationId: organizationId,
            courseId: courseId,
            fileName: fileName
        ) { [weak self] progress in
            Task { @MainActor in
                self?.uploadProgress = progress
            }
        }
        
        uploadProgress = 1.0
        return url
    }
    
    func uploadSlide(data: Data, organizationId: String, courseId: String, fileName: String) async throws -> String {
        isUploading = true
        uploadProgress = 0.0
        defer { isUploading = false }
        
        let url = try await SupabaseService.shared.uploadSlide(
            data: data,
            organizationId: organizationId,
            courseId: courseId,
            fileName: fileName
        ) { [weak self] progress in
            Task { @MainActor in
                self?.uploadProgress = progress
            }
        }
        
        uploadProgress = 1.0
        return url
    }
    
    func uploadThumbnail(data: Data, organizationId: String, courseId: String) async throws -> String {
        isUploading = true
        uploadProgress = 0.0
        defer { isUploading = false }
        
        let url = try await SupabaseService.shared.uploadThumbnail(
            data: data,
            organizationId: organizationId,
            courseId: courseId
        ) { [weak self] progress in
            Task { @MainActor in
                self?.uploadProgress = progress
            }
        }
        
        uploadProgress = 1.0
        return url
    }
    
    // MARK: - Enrollment Operations (Supabase)
    
    func enrollInCourse(learnerId: String, courseId: String) async throws -> Enrollment {
        let enrollment = Enrollment(
            id: nil,
            learnerId: learnerId,
            courseId: courseId,
            enrollmentDate: Date(),
            completionPercentage: 0.0,
            status: .active,
            lastAccessed: Date()
        )
        
        return try await SupabaseService.shared.create(enrollment, in: SupabaseConstants.enrollments)
    }
    
    func fetchEnrollmentsByLearner(learnerId: String) async throws -> [Enrollment] {
        return try await SupabaseService.shared.query(
            from: SupabaseConstants.enrollments,
            where: "learner_id",
            equals: learnerId
        )
    }
    
    func fetchEnrollmentsByCourse(courseId: String) async throws -> [Enrollment] {
        return try await SupabaseService.shared.query(
            from: SupabaseConstants.enrollments,
            where: "course_id",
            equals: courseId
        )
    }
    
    func updateEnrollment(_ enrollment: Enrollment) async throws {
        guard let id = enrollment.id else { return }
        let _: Enrollment = try await SupabaseService.shared.update(enrollment, id: id, in: SupabaseConstants.enrollments)
    }
    
    func isUserEnrolled(learnerId: String, courseId: String) async throws -> Bool {
        let enrollments: [Enrollment] = try await SupabaseService.shared.client
            .from(SupabaseConstants.enrollments)
            .select()
            .eq("learner_id", value: learnerId)
            .eq("course_id", value: courseId)
            .execute()
            .value
        return !enrollments.isEmpty
    }
    
    // MARK: - Progress Operations (Supabase)
    
    func createOrUpdateProgress(_ progress: Progress) async throws {
        if let id = progress.id {
            let _: Progress = try await SupabaseService.shared.update(progress, id: id, in: SupabaseConstants.lessonProgress)
        } else {
            let _: Progress = try await SupabaseService.shared.create(progress, in: SupabaseConstants.lessonProgress)
        }
    }
    
    func fetchProgressByEnrollment(enrollmentId: String) async throws -> [Progress] {
        return try await SupabaseService.shared.query(
            from: SupabaseConstants.lessonProgress,
            where: "enrollment_id",
            equals: enrollmentId
        )
    }
    
    func fetchProgressByLesson(enrollmentId: String, lessonId: String) async throws -> Progress? {
        let allProgress: [Progress] = try await SupabaseService.shared.queryMultiple(
            from: SupabaseConstants.lessonProgress,
            filters: [
                ("enrollment_id", enrollmentId),
                ("lesson_id", lessonId)
            ]
        )
        return allProgress.first
    }
    
    func markLessonComplete(enrollmentId: String, lessonId: String) async throws {
        if let existing = try await fetchProgressByLesson(enrollmentId: enrollmentId, lessonId: lessonId) {
            var updated = existing
            updated.isCompleted = true
            updated.completedAt = Date()
            updated.updatedAt = Date()
            try await createOrUpdateProgress(updated)
        } else {
            let newProgress = Progress(
                id: nil,
                enrollmentId: enrollmentId,
                lessonId: lessonId,
                isCompleted: true,
                timeSpentSeconds: 0,
                lastPosition: nil,
                completedAt: Date(),
                updatedAt: Date()
            )
            try await createOrUpdateProgress(newProgress)
        }
        
        // Update enrollment completion percentage
        try await updateEnrollmentProgress(enrollmentId: enrollmentId)
    }
    
    func updateEnrollmentProgress(enrollmentId: String) async throws {
        // Get the enrollment
        let enrollments: [Enrollment] = try await SupabaseService.shared.client
            .from(SupabaseConstants.enrollments)
            .select()
            .eq("id", value: enrollmentId)
            .execute()
            .value
        
        guard let enrollment = enrollments.first,
              let courseId = enrollment.courseId as String? else { return }
        
        // Get all modules for the course
        let modules = try await CourseService.shared.fetchModulesByCourse(courseId: courseId)
        
        guard !modules.isEmpty else { return }
        
        // Get all completed lessons for this enrollment
        let allProgress: [Progress] = try await SupabaseService.shared.client
            .from(SupabaseConstants.lessonProgress)
            .select()
            .eq("enrollment_id", value: enrollmentId)
            .eq("is_completed", value: true)
            .execute()
            .value
        
        let completedLessonIds = Set(allProgress.map { $0.lessonId })
        
        // Count completed modules (where ALL lessons in the module are completed)
        var completedModules = 0
        
        for module in modules {
            guard let moduleId = module.id else { continue }
            let lessons = try await CourseService.shared.fetchLessonsByModule(moduleId: moduleId)
            
            // Check if all lessons in this module are completed
            let lessonIds = lessons.compactMap { $0.id }
            if !lessonIds.isEmpty && lessonIds.allSatisfy({ completedLessonIds.contains($0) }) {
                completedModules += 1
            }
        }
        
        // Calculate percentage based on modules
        let percentage = (Double(completedModules) / Double(modules.count)) * 100.0
        
        // Update enrollment
        var updatedEnrollment = enrollment
        updatedEnrollment.completionPercentage = percentage
        updatedEnrollment.lastAccessed = Date()
        
        try await updateEnrollment(updatedEnrollment)
        
        print("✅ Updated enrollment progress: \(completedModules)/\(modules.count) modules = \(percentage)%")
    }
}
