//
//  ProgressAnalyticsService.swift
//  LTMS
//
//  Created by Assistant on 17/01/26.
//

import Foundation
import Combine
import Supabase
import PostgREST

/// Service for advanced progress analytics and tracking
@MainActor
class ProgressAnalyticsService: ObservableObject {
    static let shared = ProgressAnalyticsService()
    
    @Published var isLoading = false
    
    private let supabase = SupabaseService.shared
    
    private init() {}
    
    // MARK: - Learning Statistics
    
    /// Get comprehensive learning statistics for a learner
    func getLearningStatistics(userId: String) async throws -> LearningStatistics {
        // Fetch enrollments
        let enrollments: [Enrollment] = try await supabase.query(
            from: SupabaseConstants.enrollments,
            where: "learner_id",
            equals: userId
        )
        
        // Fetch quiz submissions
        let submissions: [QuizSubmission] = try await supabase.query(
            from: SupabaseConstants.assessmentSubmissions,
            where: "user_id",
            equals: userId
        )
        
        // Fetch progress records
        let progressRecords: [Progress] = try await fetchAllProgressForUser(userId: userId)
        
        // Calculate statistics
        let totalCourses = enrollments.count
        let completedCourses = enrollments.filter { $0.status == .completed || $0.completionPercentage >= 100 }.count
        let inProgressCourses = enrollments.filter { $0.status == .active && $0.completionPercentage > 0 && $0.completionPercentage < 100 }.count
        
        let totalTimeSpent = progressRecords.reduce(0) { $0 + $1.timeSpentSeconds }
        let averageProgress = enrollments.isEmpty ? 0 : enrollments.reduce(0.0) { $0 + $1.completionPercentage } / Double(enrollments.count)
        
        let quizzesTaken = submissions.count
        let averageQuizScore = submissions.isEmpty ? 0 : submissions.compactMap { $0.score }.reduce(0.0, +) / Double(submissions.count)
        let quizzesPassed = submissions.filter { $0.passed == true }.count
        
        return LearningStatistics(
            totalCoursesEnrolled: totalCourses,
            coursesCompleted: completedCourses,
            coursesInProgress: inProgressCourses,
            totalTimeSpentSeconds: totalTimeSpent,
            averageCompletionPercentage: averageProgress,
            quizzesTaken: quizzesTaken,
            quizzesPassed: quizzesPassed,
            averageQuizScore: averageQuizScore
        )
    }
    
    /// Fetch all progress records for a user
    private func fetchAllProgressForUser(userId: String) async throws -> [Progress] {
        // First get all enrollments for the user
        let enrollments: [Enrollment] = try await supabase.query(
            from: SupabaseConstants.enrollments,
            where: "learner_id",
            equals: userId
        )
        
        var allProgress: [Progress] = []
        
        // For each enrollment, fetch progress records
        for enrollment in enrollments {
            if let enrollmentId = enrollment.id {
                let progress: [Progress] = try await supabase.query(
                    from: SupabaseConstants.lessonProgress,
                    where: "enrollment_id",
                    equals: enrollmentId
                )
                allProgress.append(contentsOf: progress)
            }
        }
        
        return allProgress
    }
    
    // MARK: - Learning Streak
    
    /// Get or create learning streak for user
    func getLearningStreak(userId: String) async throws -> LearningStreak {
        // Try to fetch existing streak
        let streaks: [LearningStreak] = try await supabase.query(
            from: "learning_streaks",
            where: "user_id",
            equals: userId
        )
        
        if let existingStreak = streaks.first {
            return existingStreak
        } else {
            // Create new streak
            let newStreak = LearningStreak(
                id: nil,
                userId: userId,
                currentStreak: 0,
                longestStreak: 0,
                lastActivityDate: Date(),
                createdAt: Date(),
                updatedAt: Date()
            )
            return try await supabase.create(newStreak, in: "learning_streaks")
        }
    }
    
    /// Update learning streak when user completes an activity
    func updateLearningStreak(userId: String) async throws {
        var streak = try await getLearningStreak(userId: userId)
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastActivity = calendar.startOfDay(for: streak.lastActivityDate)
        
        let daysDifference = calendar.dateComponents([.day], from: lastActivity, to: today).day ?? 0
        
        if daysDifference == 0 {
            // Same day, no change to streak
            return
        } else if daysDifference == 1 {
            // Consecutive day, increment streak
            streak.currentStreak += 1
            if streak.currentStreak > streak.longestStreak {
                streak.longestStreak = streak.currentStreak
            }
        } else {
            // Streak broken, reset to 1
            streak.currentStreak = 1
        }
        
        streak.lastActivityDate = Date()
        streak.updatedAt = Date()
        
        if let id = streak.id {
            let _: LearningStreak = try await supabase.update(streak, id: id, in: "learning_streaks")
        }
    }
    
    // MARK: - Activity Timeline
    
    /// Log a learner activity
    func logActivity(
        userId: String,
        activityType: LearnerActivity.ActivityType,
        description: String,
        courseId: String? = nil,
        lessonId: String? = nil,
        quizId: String? = nil
    ) async throws {
        let activity = LearnerActivity(
            id: nil,
            userId: userId,
            activityType: activityType,
            courseId: courseId,
            lessonId: lessonId,
            quizId: quizId,
            description: description,
            timestamp: Date()
        )
        
        let _: LearnerActivity = try await supabase.create(activity, in: "learner_activities")
        
        // Update streak
        try await updateLearningStreak(userId: userId)
    }
    
    /// Fetch recent activities for a user
    func getRecentActivities(userId: String, limit: Int = 20) async throws -> [LearnerActivity] {
        let response = try await supabase.client
            .from("learner_activities")
            .select()
            .eq("user_id", value: userId)
            .order("timestamp", ascending: false)
            .limit(limit)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([LearnerActivity].self, from: response.data)
    }
    
    // MARK: - Course-Level Analytics
    
    /// Get detailed analytics for a specific course enrollment
    func getCourseAnalytics(enrollmentId: String) async throws -> CourseAnalytics {
        let enrollment: Enrollment = try await supabase.fetch(id: enrollmentId, from: SupabaseConstants.enrollments)
        let course: Course = try await supabase.fetch(id: enrollment.courseId, from: SupabaseConstants.courses)
        
        // Fetch progress for this enrollment
        let progressRecords: [Progress] = try await supabase.query(
            from: SupabaseConstants.lessonProgress,
            where: "enrollment_id",
            equals: enrollmentId
        )
        
        let totalLessons = progressRecords.count
        let completedLessons = progressRecords.filter { $0.isCompleted }.count
        let totalTimeSpent = progressRecords.reduce(0) { $0 + $1.timeSpentSeconds }
        
        return CourseAnalytics(
            course: course,
            enrollment: enrollment,
            totalLessons: totalLessons,
            completedLessons: completedLessons,
            totalTimeSpentSeconds: totalTimeSpent
        )
    }
}

// MARK: - Supporting Models

struct LearningStatistics {
    let totalCoursesEnrolled: Int
    let coursesCompleted: Int
    let coursesInProgress: Int
    let totalTimeSpentSeconds: Int
    let averageCompletionPercentage: Double
    let quizzesTaken: Int
    let quizzesPassed: Int
    let averageQuizScore: Double
    
    var formattedTotalTime: String {
        let hours = totalTimeSpentSeconds / 3600
        let minutes = (totalTimeSpentSeconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var quizPassRate: Double {
        guard quizzesTaken > 0 else { return 0 }
        return (Double(quizzesPassed) / Double(quizzesTaken)) * 100
    }
}

struct CourseAnalytics {
    let course: Course
    let enrollment: Enrollment
    let totalLessons: Int
    let completedLessons: Int
    let totalTimeSpentSeconds: Int
    
    var completionRate: Double {
        guard totalLessons > 0 else { return 0 }
        return (Double(completedLessons) / Double(totalLessons)) * 100
    }
    
    var formattedTimeSpent: String {
        let hours = totalTimeSpentSeconds / 3600
        let minutes = (totalTimeSpentSeconds % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
