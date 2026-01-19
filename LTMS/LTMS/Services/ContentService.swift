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
        print("📝 [Enrollment] Creating enrollment for learner: \(learnerId) in course: \(courseId)")
        
        let enrollment = Enrollment(
            id: nil,
            learnerId: learnerId,
            courseId: courseId,
            enrollmentDate: Date(),
            completionPercentage: 0.0,
            status: .active,
            lastAccessed: Date(),
            enrolledBy: "self",
            completedAt: nil,
            certificateIssued: false
        )
        
        let createdEnrollment = try await SupabaseService.shared.create(enrollment, in: SupabaseConstants.enrollments)
        print("✅ [Enrollment] Successfully created enrollment with ID: \(createdEnrollment.id ?? "unknown")")
        
        // Log enrollment activity
        do {
            let course = try await CourseService.shared.fetchCourse(id: courseId)
            try await ProgressAnalyticsService.shared.logActivity(
                userId: learnerId,
                activityType: .enrollment,
                description: "Enrolled in \(course.title)",
                courseId: courseId
            )
        } catch {
            print("⚠️ Failed to log enrollment activity: \(error)")
        }
        
        return createdEnrollment
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
    
    // MARK: - Quiz Operations (Supabase)
    
    func fetchQuizzesByLesson(lessonId: String) async throws -> [Quiz] {
        return try await SupabaseService.shared.query(
            from: SupabaseConstants.assessments,
            where: "lesson_id",
            equals: lessonId
        )
    }
    
    func fetchQuizSubmissionsByUser(userId: String, courseId: String) async throws -> [QuizSubmission] {
        // Get all quizzes for the course first
        let quizzes: [Quiz] = try await SupabaseService.shared.query(
            from: SupabaseConstants.assessments,
            where: "course_id",
            equals: courseId
        )
        
        let quizIds = quizzes.compactMap { $0.id }
        
        // Fetch submissions for these quizzes by this user
        var submissions: [QuizSubmission] = []
        for quizId in quizIds {
            let quizSubmissions: [QuizSubmission] = try await SupabaseService.shared.queryMultiple(
                from: SupabaseConstants.assessmentSubmissions,
                filters: [
                    ("assessment_id", quizId),
                    ("user_id", userId)
                ]
            )
            submissions.append(contentsOf: quizSubmissions)
        }
        
        return submissions
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
    
    func updateContentProgress(enrollmentId: String, lessonId: String, timeSpent: Int, position: String?) async throws {
        // Get or create progress record
        var progress: Progress
        
        if let existing = try await fetchProgressByLesson(enrollmentId: enrollmentId, lessonId: lessonId) {
            progress = existing
            progress.timeSpentSeconds += timeSpent
            progress.lastPosition = position
            progress.updatedAt = Date()
        } else {
            progress = Progress(
                id: nil,
                enrollmentId: enrollmentId,
                lessonId: lessonId,
                isCompleted: false,
                timeSpentSeconds: timeSpent,
                lastPosition: position,
                completedAt: nil,
                updatedAt: Date()
            )
        }
        
        try await createOrUpdateProgress(progress)
        
        // Update enrollment last accessed
        let enrollments: [Enrollment] = try await SupabaseService.shared.client
            .from(SupabaseConstants.enrollments)
            .select()
            .eq("id", value: enrollmentId)
            .execute()
            .value
        
        if var enrollment = enrollments.first {
            enrollment.lastAccessed = Date()
            try await updateEnrollment(enrollment)
        }
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
        
        // Log lesson completion activity
        do {
            let enrollments: [Enrollment] = try await SupabaseService.shared.client
                .from(SupabaseConstants.enrollments)
                .select()
                .eq("id", value: enrollmentId)
                .execute()
                .value
            
            if let enrollment = enrollments.first {
                let lesson = try await CourseService.shared.fetchLessonsByModule(moduleId: "").first { $0.id == lessonId }
                try await ProgressAnalyticsService.shared.logActivity(
                    userId: enrollment.learnerId,
                    activityType: .lessonComplete,
                    description: "Completed lesson: \(lesson?.title ?? "Lesson")",
                    courseId: enrollment.courseId,
                    lessonId: lessonId
                )
            }
        } catch {
            print("⚠️ Failed to log lesson completion activity: \(error)")
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
        
        // Get all quizzes for the course
        let allQuizzes: [Quiz] = try await SupabaseService.shared.client
            .from(SupabaseConstants.assessments)
            .select()
            .eq("course_id", value: courseId)
            .execute()
            .value
        
        // Get all passed quiz submissions for this user
        let passedSubmissions: [QuizSubmission] = try await SupabaseService.shared.client
            .from(SupabaseConstants.assessmentSubmissions)
            .select()
            .eq("user_id", value: enrollment.learnerId)
            .eq("passed", value: true)
            .execute()
            .value
        
        let passedQuizIds = Set(passedSubmissions.map { $0.assessmentId })
        
        // Count total items (lessons + quizzes) and completed items
        var totalItems = 0
        var completedItems = 0
        
        for module in modules {
            guard let moduleId = module.id else { continue }
            let lessons = try await CourseService.shared.fetchLessonsByModule(moduleId: moduleId)
            
            // Get lesson IDs for this module
            let lessonIds = lessons.compactMap { $0.id }
            
            // Get quizzes for lessons in this module
            let moduleQuizzes = allQuizzes.filter { quiz in
                if let quizLessonId = quiz.lessonId {
                    return lessonIds.contains(quizLessonId)
                }
                return false
            }
            
            // Count lessons
            totalItems += lessonIds.count
            completedItems += lessonIds.filter { completedLessonIds.contains($0) }.count
            
            // Count quizzes
            let quizIds = moduleQuizzes.compactMap { $0.id }
            totalItems += quizIds.count
            completedItems += quizIds.filter { passedQuizIds.contains($0) }.count
        }
        
        // Calculate percentage based on individual items
        let percentage = totalItems > 0 ? (Double(completedItems) / Double(totalItems)) * 100.0 : 0.0
        
        // Update enrollment
        var updatedEnrollment = enrollment
        updatedEnrollment.completionPercentage = percentage
        updatedEnrollment.lastAccessed = Date()
        
        // Auto-complete course if 100% done
        if percentage >= 100.0 && updatedEnrollment.status != .completed {
            updatedEnrollment.status = .completed
            updatedEnrollment.completedAt = Date()
            updatedEnrollment.certificateIssued = true
            print("🎉 Course completed! Certificate issued.")
            
            // Log course completion activity
            do {
                let course = try await CourseService.shared.fetchCourse(id: courseId)
                try await ProgressAnalyticsService.shared.logActivity(
                    userId: enrollment.learnerId,
                    activityType: .courseComplete,
                    description: "Completed \(course.title)",
                    courseId: courseId
                )
            } catch {
                print("⚠️ Failed to log course completion activity: \(error)")
            }
        }
        
        try await updateEnrollment(updatedEnrollment)
        
        print("✅ Updated enrollment progress: \(completedItems)/\(totalItems) items = \(String(format: "%.1f", percentage))%")
    }
}
