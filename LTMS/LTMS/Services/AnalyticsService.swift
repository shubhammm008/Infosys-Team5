//
//  AnalyticsService.swift
//  LTMS
//
//  Created by AI Assistant on 13/01/26.
//

import Foundation

struct PlatformMetrics: Codable {
    var totalUsers: Int
    var activeUsersLast7Days: Int
    var activeUsersLast30Days: Int
    var totalCourses: Int
    var totalEnrollments: Int
    var totalLearningTimeHours: Double
    var averageCompletionRate: Double
}

struct CourseCompletionStats: Codable {
    var courseId: String
    var courseTitle: String
    var totalEnrollments: Int
    var completedEnrollments: Int
    var activeEnrollments: Int
    var droppedEnrollments: Int
    var completionRate: Double
    var averageCompletionPercentage: Double
    var averageTimeToComplete: Double? // in days
}

struct EnrollmentTrend: Codable {
    var date: Date
    var enrollmentCount: Int
    var completionCount: Int
}

struct PopularCourse: Codable {
    var courseId: String
    var courseTitle: String
    var enrollmentCount: Int
    var averageRating: Double?
}

struct UserActivityMetrics: Codable {
    var userId: String
    var userName: String
    var loginCount: Int
    var lastLogin: Date?
    var totalEnrollments: Int
    var completedCourses: Int
    var totalLearningTimeHours: Double
}

class AnalyticsService {
    private let supabaseService = SupabaseService.shared
    
    // MARK: - Platform Metrics
    
    func fetchPlatformMetrics(organizationId: String) async throws -> PlatformMetrics {
        // Fetch all users
        let users: [User] = try await supabaseService.query(
            from: SupabaseConstants.users,
            where: "organization_id",
            equals: organizationId
        )
        
        // Calculate active users
        let now = Date()
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
        
        let activeUsersLast7Days = users.filter { user in
            guard let lastLogin = user.lastLogin else { return false }
            return lastLogin >= sevenDaysAgo
        }.count
        
        let activeUsersLast30Days = users.filter { user in
            guard let lastLogin = user.lastLogin else { return false }
            return lastLogin >= thirtyDaysAgo
        }.count
        
        // Fetch courses
        let courses: [Course] = try await supabaseService.query(
            from: SupabaseConstants.courses,
            where: "organization_id",
            equals: organizationId
        )
        
        // Fetch all enrollments - get all and filter
        let allEnrollments: [Enrollment] = try await supabaseService.fetchAll(from: SupabaseConstants.enrollments)
        let enrollments = allEnrollments // For now, include all (could filter by org if needed)
        
        // Calculate total learning time
        var totalLearningTimeSeconds: Double = 0
        for enrollment in enrollments {
            if let enrollmentId = enrollment.id {
                let progress: [Progress] = try await supabaseService.query(
                    from: SupabaseConstants.lessonProgress,
                    where: "enrollment_id",
                    equals: enrollmentId
                )
                totalLearningTimeSeconds += progress.reduce(0) { $0 + Double($1.timeSpentSeconds) }
            }
        }
        
        // Calculate average completion rate
        let completionSum = enrollments.reduce(0.0) { $0 + $1.completionPercentage }
        let averageCompletionRate = enrollments.isEmpty ? 0 : completionSum / Double(enrollments.count)
        
        return PlatformMetrics(
            totalUsers: users.count,
            activeUsersLast7Days: activeUsersLast7Days,
            activeUsersLast30Days: activeUsersLast30Days,
            totalCourses: courses.count,
            totalEnrollments: enrollments.count,
            totalLearningTimeHours: totalLearningTimeSeconds / 3600,
            averageCompletionRate: averageCompletionRate
        )
    }
    
    // MARK: - Course Completion Statistics
    
    func fetchCourseCompletionStats(courseId: String) async throws -> CourseCompletionStats {
        // Fetch course
        let course: Course = try await supabaseService.fetch(id: courseId, from: SupabaseConstants.courses)
        guard course.id != nil else {
            throw NSError(domain: "AnalyticsService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Course not found"])
        }
        
        // Fetch enrollments for this course
        let enrollments: [Enrollment] = try await supabaseService.query(
            from: SupabaseConstants.enrollments,
            where: "course_id",
            equals: courseId
        )
        
        let totalEnrollments = enrollments.count
        let completedEnrollments = enrollments.filter { $0.status == .completed }.count
        let activeEnrollments = enrollments.filter { $0.status == .active }.count
        let droppedEnrollments = enrollments.filter { $0.status == .dropped }.count
        
        let completionRate = totalEnrollments > 0 ? (Double(completedEnrollments) / Double(totalEnrollments)) * 100 : 0
        
        let completionSum = enrollments.reduce(0.0) { $0 + $1.completionPercentage }
        let averageCompletionPercentage = totalEnrollments > 0 ? completionSum / Double(totalEnrollments) : 0
        
        // Calculate average time to complete
        var totalTimeToComplete: Double = 0
        var completedCount = 0
        
        for enrollment in enrollments where enrollment.status == .completed {
            if let completedAt = enrollment.completedAt {
                let timeInterval = completedAt.timeIntervalSince(enrollment.enrollmentDate)
                totalTimeToComplete += timeInterval / 86400 // Convert to days
                completedCount += 1
            }
        }
        
        let averageTimeToComplete = completedCount > 0 ? totalTimeToComplete / Double(completedCount) : nil
        
        return CourseCompletionStats(
            courseId: courseId,
            courseTitle: course.title,
            totalEnrollments: totalEnrollments,
            completedEnrollments: completedEnrollments,
            activeEnrollments: activeEnrollments,
            droppedEnrollments: droppedEnrollments,
            completionRate: completionRate,
            averageCompletionPercentage: averageCompletionPercentage,
            averageTimeToComplete: averageTimeToComplete
        )
    }
    
    func fetchAllCourseCompletionStats(organizationId: String) async throws -> [CourseCompletionStats] {
        let courses: [Course] = try await supabaseService.query(
            from: SupabaseConstants.courses,
            where: "organization_id",
            equals: organizationId
        )
        
        var stats: [CourseCompletionStats] = []
        for course in courses {
            if let courseId = course.id {
                let courseStat = try await fetchCourseCompletionStats(courseId: courseId)
                stats.append(courseStat)
            }
        }
        
        return stats
    }
    
    // MARK: - Enrollment Trends
    
    func fetchEnrollmentTrends(organizationId: String, days: Int = 30) async throws -> [EnrollmentTrend] {
        let allEnrollments: [Enrollment] = try await supabaseService.fetchAll(from: SupabaseConstants.enrollments)
        let enrollments = allEnrollments // For now, include all
        
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: now) ?? now
        
        // Group enrollments by date
        var trendDict: [Date: (enrollments: Int, completions: Int)] = [:]
        
        for enrollment in enrollments {
            let enrollmentDay = calendar.startOfDay(for: enrollment.enrollmentDate)
            if enrollmentDay >= startDate {
                var current = trendDict[enrollmentDay] ?? (enrollments: 0, completions: 0)
                current.enrollments += 1
                trendDict[enrollmentDay] = current
            }
            
            // Count completions
            if let completedAt = enrollment.completedAt {
                let completionDay = calendar.startOfDay(for: completedAt)
                if completionDay >= startDate {
                    var current = trendDict[completionDay] ?? (enrollments: 0, completions: 0)
                    current.completions += 1
                    trendDict[completionDay] = current
                }
            }
        }
        
        // Convert to array and sort
        let trends = trendDict.map { date, counts in
            EnrollmentTrend(date: date, enrollmentCount: counts.enrollments, completionCount: counts.completions)
        }.sorted { $0.date < $1.date }
        
        return trends
    }
    
    // MARK: - Popular Courses
    
    func fetchPopularCourses(organizationId: String, limit: Int = 10) async throws -> [PopularCourse] {
        let courses: [Course] = try await supabaseService.query(
            from: SupabaseConstants.courses,
            where: "organization_id",
            equals: organizationId
        )
        
        var popularCourses: [PopularCourse] = []
        
        for course in courses {
            guard let courseId = course.id else { continue }
            
            let enrollments: [Enrollment] = try await supabaseService.query(
                from: SupabaseConstants.enrollments,
                where: "course_id",
                equals: courseId
            )
            
            popularCourses.append(PopularCourse(
                courseId: courseId,
                courseTitle: course.title,
                enrollmentCount: enrollments.count,
                averageRating: nil // Can be implemented when ratings are added
            ))
        }
        
        // Sort by enrollment count and limit
        return popularCourses.sorted { $0.enrollmentCount > $1.enrollmentCount }.prefix(limit).map { $0 }
    }
    
    // MARK: - User Activity Metrics
    
    func fetchUserActivityMetrics(organizationId: String, role: UserRole? = nil) async throws -> [UserActivityMetrics] {
        let users: [User]
        if let role = role {
            users = try await supabaseService.queryMultiple(
                from: SupabaseConstants.users,
                filters: [("organization_id", organizationId), ("role", role.rawValue)]
            )
        } else {
            users = try await supabaseService.query(
                from: SupabaseConstants.users,
                where: "organization_id",
                equals: organizationId
            )
        }
        
        var metrics: [UserActivityMetrics] = []
        
        for user in users {
            guard let userId = user.id else { continue }
            
            // Fetch user enrollments
            let enrollments: [Enrollment] = try await supabaseService.query(
                from: SupabaseConstants.enrollments,
                where: "learner_id",
                equals: userId
            )
            
            let completedCourses = enrollments.filter { $0.status == .completed }.count
            
            // Calculate total learning time
            var totalLearningTimeSeconds: Double = 0
            for enrollment in enrollments {
                if let enrollmentId = enrollment.id {
                    let progress: [Progress] = try await supabaseService.query(
                        from: SupabaseConstants.lessonProgress,
                        where: "enrollment_id",
                        equals: enrollmentId
                    )
                    totalLearningTimeSeconds += progress.reduce(0) { $0 + Double($1.timeSpentSeconds) }
                }
            }
            
            metrics.append(UserActivityMetrics(
                userId: userId,
                userName: user.fullName,
                loginCount: user.loginCount,
                lastLogin: user.lastLogin,
                totalEnrollments: enrollments.count,
                completedCourses: completedCourses,
                totalLearningTimeHours: totalLearningTimeSeconds / 3600
            ))
        }
        
        return metrics.sorted { $0.loginCount > $1.loginCount }
    }
    
    // MARK: - Enrollment Management
    
    func fetchEnrollmentDetails(courseId: String) async throws -> [(enrollment: Enrollment, user: User)] {
        let enrollments: [Enrollment] = try await supabaseService.query(
            from: SupabaseConstants.enrollments,
            where: "course_id",
            equals: courseId
        )
        
        var enrollmentDetails: [(enrollment: Enrollment, user: User)] = []
        
        for enrollment in enrollments {
            if let user = try? await supabaseService.fetch(id: enrollment.learnerId, from: SupabaseConstants.users) as User {
                enrollmentDetails.append((enrollment: enrollment, user: user))
            }
        }
        
        return enrollmentDetails
    }
    
    func enrollUserInCourse(userId: String, courseId: String, enrolledBy: String) async throws -> Enrollment {
        // Check if already enrolled
        let existingEnrollments: [Enrollment] = try await supabaseService.queryMultiple(
            from: SupabaseConstants.enrollments,
            filters: [("learner_id", userId), ("course_id", courseId)]
        )
        
        if !existingEnrollments.isEmpty {
            throw NSError(domain: "AnalyticsService", code: 409, userInfo: [NSLocalizedDescriptionKey: "User already enrolled in this course"])
        }
        
        // Check max enrollments
        if let course = try? await supabaseService.fetch(id: courseId, from: SupabaseConstants.courses) as Course,
           let maxEnrollments = course.maxEnrollments {
            let currentEnrollments: [Enrollment] = try await supabaseService.query(
                from: SupabaseConstants.enrollments,
                where: "course_id",
                equals: courseId
            )
            
            if currentEnrollments.count >= maxEnrollments {
                throw NSError(domain: "AnalyticsService", code: 403, userInfo: [NSLocalizedDescriptionKey: "Course enrollment limit reached"])
            }
        }
        
        let enrollment = Enrollment(
            id: nil,
            learnerId: userId,
            courseId: courseId,
            enrollmentDate: Date(),
            completionPercentage: 0,
            status: .active,
            lastAccessed: nil,
            enrolledBy: enrolledBy,
            completedAt: nil,
            certificateIssued: false
        )
        
        return try await supabaseService.create(enrollment, in: SupabaseConstants.enrollments)
    }
    
    func unenrollUser(enrollmentId: String) async throws {
        try await supabaseService.delete(id: enrollmentId, from: SupabaseConstants.enrollments)
    }
    
    func updateEnrollmentStatus(enrollmentId: String, status: EnrollmentStatus) async throws {
        var enrollment: Enrollment = try await supabaseService.fetch(id: enrollmentId, from: SupabaseConstants.enrollments)
        
        enrollment.status = status
        if status == .completed && enrollment.completedAt == nil {
            enrollment.completedAt = Date()
        }
        
        _ = try await supabaseService.update(enrollment, id: enrollmentId, in: SupabaseConstants.enrollments)
    }
}
