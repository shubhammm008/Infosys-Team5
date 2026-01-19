//
//  RecommendationService.swift
//  LTMS
//
//  Created by Assistant on 17/01/26.
//

import Foundation
import Combine

/// Service for generating personalized course recommendations
@MainActor
class RecommendationService: ObservableObject {
    static let shared = RecommendationService()
    
    @Published var isLoading = false
    
    private let supabase = SupabaseService.shared
    
    private init() {}
    
    // MARK: - Course Recommendations
    
    /// Get personalized course recommendations for a user
    func getRecommendations(userId: String, limit: Int = 5) async throws -> [CourseRecommendation] {
        var recommendations: [CourseRecommendation] = []
        
        // Fetch user's learning profile
        let profile = try await buildUserProfile(userId: userId)
        
        // Fetch all available courses
        let allCourses: [Course] = try await supabase.fetchAll(from: SupabaseConstants.courses)
        let publishedCourses = allCourses.filter { $0.isPublished && $0.isCurrentlyAvailable }
        
        // Filter out already enrolled courses
        let unenrolledCourses = publishedCourses.filter { course in
            !profile.enrolledCourseIds.contains(course.id ?? "")
        }
        
        // Generate collaborative filtering recommendations
        let collaborativeRecs = try await generateCollaborativeRecommendations(
            userId: userId,
            profile: profile,
            availableCourses: unenrolledCourses
        )
        recommendations.append(contentsOf: collaborativeRecs)
        
        // Generate content-based recommendations
        let contentBasedRecs = generateContentBasedRecommendations(
            profile: profile,
            availableCourses: unenrolledCourses
        )
        recommendations.append(contentsOf: contentBasedRecs)
        
        // Add popular courses
        let popularRecs = try await generatePopularRecommendations(
            availableCourses: unenrolledCourses
        )
        recommendations.append(contentsOf: popularRecs)
        
        // Sort by score and return top recommendations
        let sortedRecs = recommendations
            .sorted { $0.score > $1.score }
            .prefix(limit)
        
        return Array(sortedRecs)
    }
    
    // MARK: - Learning Paths
    
    /// Generate personalized learning paths
    func generateLearningPaths(userId: String) async throws -> [LearningPath] {
        let profile = try await buildUserProfile(userId: userId)
        let allCourses: [Course] = try await supabase.fetchAll(from: SupabaseConstants.courses)
        let publishedCourses = allCourses.filter { $0.isPublished && $0.isCurrentlyAvailable }
        
        var paths: [LearningPath] = []
        
        // Beginner to Advanced Path
        let beginnerCourses = publishedCourses.filter { $0.level == .beginner && !profile.completedCourseIds.contains($0.id ?? "") }
        let intermediateCourses = publishedCourses.filter { $0.level == .intermediate && !profile.completedCourseIds.contains($0.id ?? "") }
        let advancedCourses = publishedCourses.filter { $0.level == .advanced && !profile.completedCourseIds.contains($0.id ?? "") }
        
        if !beginnerCourses.isEmpty {
            let path = LearningPath(
                id: UUID().uuidString,
                title: "Foundation to Mastery",
                description: "Start from basics and progress to advanced topics",
                courses: Array(beginnerCourses.prefix(2)) + Array(intermediateCourses.prefix(2)) + Array(advancedCourses.prefix(1)),
                estimatedDuration: (Array(beginnerCourses.prefix(2)) + Array(intermediateCourses.prefix(2)) + Array(advancedCourses.prefix(1))).reduce(0) { $0 + $1.durationHours },
                difficulty: .beginner,
                completionPercentage: calculatePathCompletion(
                    courses: Array(beginnerCourses.prefix(2)) + Array(intermediateCourses.prefix(2)) + Array(advancedCourses.prefix(1)),
                    profile: profile
                )
            )
            paths.append(path)
        }
        
        // Quick Skills Path (shorter courses)
        let quickCourses = publishedCourses
            .filter { $0.durationHours <= 10 && !profile.completedCourseIds.contains($0.id ?? "") }
            .prefix(4)
        
        if !quickCourses.isEmpty {
            let path = LearningPath(
                id: UUID().uuidString,
                title: "Quick Skills Boost",
                description: "Short courses to quickly gain new skills",
                courses: Array(quickCourses),
                estimatedDuration: Array(quickCourses).reduce(0) { $0 + $1.durationHours },
                difficulty: .beginner,
                completionPercentage: calculatePathCompletion(courses: Array(quickCourses), profile: profile)
            )
            paths.append(path)
        }
        
        // Comprehensive Path (longer, in-depth courses)
        let comprehensiveCourses = publishedCourses
            .filter { $0.durationHours > 20 && !profile.completedCourseIds.contains($0.id ?? "") }
            .prefix(3)
        
        if !comprehensiveCourses.isEmpty {
            let path = LearningPath(
                id: UUID().uuidString,
                title: "Deep Dive Mastery",
                description: "Comprehensive courses for in-depth expertise",
                courses: Array(comprehensiveCourses),
                estimatedDuration: Array(comprehensiveCourses).reduce(0) { $0 + $1.durationHours },
                difficulty: .advanced,
                completionPercentage: calculatePathCompletion(courses: Array(comprehensiveCourses), profile: profile)
            )
            paths.append(path)
        }
        
        return paths
    }
    
    // MARK: - Private Helper Methods
    
    /// Build user learning profile
    private func buildUserProfile(userId: String) async throws -> UserLearningProfile {
        let enrollments: [Enrollment] = try await supabase.query(
            from: SupabaseConstants.enrollments,
            where: "learner_id",
            equals: userId
        )
        
        let submissions: [QuizSubmission] = try await supabase.query(
            from: SupabaseConstants.assessmentSubmissions,
            where: "user_id",
            equals: userId
        )
        
        let enrolledCourseIds = enrollments.map { $0.courseId }
        let completedCourseIds = enrollments.filter { $0.status == .completed }.map { $0.courseId }
        
        let averageScore = submissions.isEmpty ? 0 : submissions.compactMap { $0.score }.reduce(0.0, +) / Double(submissions.count)
        
        return UserLearningProfile(
            userId: userId,
            enrolledCourseIds: enrolledCourseIds,
            completedCourseIds: completedCourseIds,
            preferredTopics: [], // Could be enhanced with topic extraction
            averageQuizScore: averageScore,
            totalTimeSpent: 0,
            lastActiveDate: Date()
        )
    }
    
    /// Generate collaborative filtering recommendations
    private func generateCollaborativeRecommendations(
        userId: String,
        profile: UserLearningProfile,
        availableCourses: [Course]
    ) async throws -> [CourseRecommendation] {
        // Find similar learners (those who took similar courses)
        let allEnrollments: [Enrollment] = try await supabase.fetchAll(from: SupabaseConstants.enrollments)
        
        // Group enrollments by user
        var userCourses: [String: Set<String>] = [:]
        for enrollment in allEnrollments {
            userCourses[enrollment.learnerId, default: []].insert(enrollment.courseId)
        }
        
        let currentUserCourses = Set(profile.enrolledCourseIds)
        
        // Find users with similar course enrollments
        var similarityScores: [(userId: String, score: Double)] = []
        for (otherUserId, otherCourses) in userCourses where otherUserId != userId {
            let intersection = currentUserCourses.intersection(otherCourses)
            let union = currentUserCourses.union(otherCourses)
            let similarity = union.isEmpty ? 0 : Double(intersection.count) / Double(union.count)
            
            if similarity > 0.2 { // At least 20% similarity
                similarityScores.append((otherUserId, similarity))
            }
        }
        
        // Get courses taken by similar users
        var courseScores: [String: Double] = [:]
        for (similarUserId, similarity) in similarityScores {
            let similarUserCourses = userCourses[similarUserId] ?? []
            for courseId in similarUserCourses where !currentUserCourses.contains(courseId) {
                courseScores[courseId, default: 0] += similarity
            }
        }
        
        // Create recommendations
        var recommendations: [CourseRecommendation] = []
        for course in availableCourses {
            if let score = courseScores[course.id ?? ""], score > 0 {
                recommendations.append(CourseRecommendation(
                    id: course.id ?? UUID().uuidString,
                    course: course,
                    score: min(score, 1.0),
                    reason: "Popular among learners with similar interests",
                    recommendationType: .collaborative
                ))
            }
        }
        
        return recommendations.sorted { $0.score > $1.score }.prefix(3).map { $0 }
    }
    
    /// Generate content-based recommendations
    private func generateContentBasedRecommendations(
        profile: UserLearningProfile,
        availableCourses: [Course]
    ) -> [CourseRecommendation] {
        var recommendations: [CourseRecommendation] = []
        
        // Recommend courses at appropriate difficulty level
        let targetLevel: CourseLevel
        if profile.averageQuizScore >= 80 {
            targetLevel = .advanced
        } else if profile.averageQuizScore >= 60 {
            targetLevel = .intermediate
        } else {
            targetLevel = .beginner
        }
        
        for course in availableCourses where course.level == targetLevel {
            let score = 0.7 // Base score for matching difficulty
            recommendations.append(CourseRecommendation(
                id: course.id ?? UUID().uuidString,
                course: course,
                score: score,
                reason: "Matches your skill level (\(targetLevel.displayName))",
                recommendationType: .contentBased
            ))
        }
        
        return recommendations.prefix(2).map { $0 }
    }
    
    /// Generate popular course recommendations
    private func generatePopularRecommendations(
        availableCourses: [Course]
    ) async throws -> [CourseRecommendation] {
        let allEnrollments: [Enrollment] = try await supabase.fetchAll(from: SupabaseConstants.enrollments)
        
        // Count enrollments per course
        var enrollmentCounts: [String: Int] = [:]
        for enrollment in allEnrollments {
            enrollmentCounts[enrollment.courseId, default: 0] += 1
        }
        
        // Create recommendations for popular courses
        var recommendations: [CourseRecommendation] = []
        for course in availableCourses {
            let count = enrollmentCounts[course.id ?? ""] ?? 0
            if count > 0 {
                let score = min(Double(count) / 10.0, 1.0) * 0.6 // Scale and cap at 0.6
                recommendations.append(CourseRecommendation(
                    id: course.id ?? UUID().uuidString,
                    course: course,
                    score: score,
                    reason: "\(count) learners enrolled",
                    recommendationType: .popular
                ))
            }
        }
        
        return recommendations.sorted { $0.score > $1.score }.prefix(2).map { $0 }
    }
    
    /// Calculate learning path completion percentage
    private func calculatePathCompletion(courses: [Course], profile: UserLearningProfile) -> Double {
        guard !courses.isEmpty else { return 0 }
        
        let completedCount = courses.filter { course in
            profile.completedCourseIds.contains(course.id ?? "")
        }.count
        
        return (Double(completedCount) / Double(courses.count)) * 100
    }
}
