//
//  SupabaseService.swift
//  LTMS
//
//  Created for Supabase Integration
//

import Foundation
import Supabase
import PostgREST

class SupabaseService {
    static let shared = SupabaseService()
    
    private let client: SupabaseClient
    
    // Custom decoder for Supabase responses with ISO8601 dates
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    // Custom encoder for Supabase requests with ISO8601 dates
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    
    private init() {
        self.client = SupabaseConfig.shared.client
    }
    
    // MARK: - Generic CRUD Operations
    
    /// Create a new record in a table
    func create<T: Codable>(_ item: T, in table: String) async throws -> T {
        let response = try await client
            .from(table)
            .insert(item)
            .select()
            .single()
            .execute()
        
        return try decoder.decode(T.self, from: response.data)
    }
    
    /// Update a record by ID
    func update<T: Codable>(_ item: T, id: String, in table: String) async throws -> T {
        let response = try await client
            .from(table)
            .update(item)
            .eq("id", value: id)
            .select()
            .single()
            .execute()
        
        return try decoder.decode(T.self, from: response.data)
    }
    
    /// Delete a record by ID
    func delete(id: String, from table: String) async throws {
        try await client
            .from(table)
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    /// Fetch a single record by ID
    func fetch<T: Codable>(id: String, from table: String) async throws -> T {
        let response = try await client
            .from(table)
            .select()
            .eq("id", value: id)
            .single()
            .execute()
        
        return try decoder.decode(T.self, from: response.data)
    }
    
    /// Fetch all records from a table
    func fetchAll<T: Codable>(from table: String) async throws -> [T] {
        let response = try await client
            .from(table)
            .select()
            .execute()
        
        return try decoder.decode([T].self, from: response.data)
    }
    
    /// Query records with a filter
    func query<T: Codable>(
        from table: String,
        where field: String,
        equals value: String
    ) async throws -> [T] {
        let response = try await client
            .from(table)
            .select()
            .eq(field, value: value)
            .execute()
        
        return try decoder.decode([T].self, from: response.data)
    }
    
    /// Query records with multiple filters
    func queryMultiple<T: Codable>(
        from table: String,
        filters: [(field: String, value: String)]
    ) async throws -> [T] {
        var query = client.from(table).select()
        
        for filter in filters {
            query = query.eq(filter.field, value: filter.value)
        }
        
        let response = try await query.execute()
        return try decoder.decode([T].self, from: response.data)
    }
    
    // MARK: - User-Specific Operations
    
    /// Fetch user by email
    func fetchUserByEmail(_ email: String) async throws -> User? {
        let users: [User] = try await query(
            from: SupabaseConstants.users,
            where: "email",
            equals: email
        )
        return users.first
    }
    
    /// Fetch all users in an organization
    func fetchUsersInOrganization(_ organizationId: String) async throws -> [User] {
        return try await query(
            from: SupabaseConstants.users,
            where: "organization_id",
            equals: organizationId
        )
    }
    
    /// Fetch users by role
    func fetchUsersByRole(_ role: UserRole, in organizationId: String) async throws -> [User] {
        return try await queryMultiple(
            from: SupabaseConstants.users,
            filters: [
                ("organization_id", organizationId),
                ("role", role.rawValue)
            ]
        )
    }
    
    // MARK: - Course-Specific Operations
    
    /// Fetch published courses
    func fetchPublishedCourses(in organizationId: String) async throws -> [Course] {
        return try await queryMultiple(
            from: SupabaseConstants.courses,
            filters: [
                ("organization_id", organizationId),
                ("is_published", "true")
            ]
        )
    }
    
    /// Fetch courses created by a user
    func fetchCoursesByCreator(_ userId: String) async throws -> [Course] {
        return try await query(
            from: SupabaseConstants.courses,
            where: "created_by",
            equals: userId
        )
    }
    
    /// Fetch courses assigned to an educator
    func fetchCoursesForEducator(_ educatorId: String) async throws -> [Course] {
        // This requires a join, which we'll handle with a custom query
        let response = try await client
            .from(SupabaseConstants.courses)
            .select("""
                *,
                course_assignments!inner(educator_id)
            """)
            .eq("course_assignments.educator_id", value: educatorId)
            .execute()
        
        return try decoder.decode([Course].self, from: response.data)
    }
    
    // MARK: - Enrollment Operations
    
    /// Enroll a user in a course
    func enrollUser(_ userId: String, in courseId: String) async throws -> Enrollment {
        let enrollment = Enrollment(
            id: nil,
            learnerId: userId,
            courseId: courseId,
            enrollmentDate: Date(),
            completionPercentage: 0.0,
            status: .active,
            lastAccessed: nil
        )
        
        return try await create(enrollment, in: SupabaseConstants.enrollments)
    }
    
    /// Fetch user's enrollments
    func fetchEnrollmentsForUser(_ userId: String) async throws -> [Enrollment] {
        return try await query(
            from: SupabaseConstants.enrollments,
            where: "learner_id",
            equals: userId
        )
    }
    
    /// Fetch enrollments for a course
    func fetchEnrollmentsForCourse(_ courseId: String) async throws -> [Enrollment] {
        return try await query(
            from: SupabaseConstants.enrollments,
            where: "course_id",
            equals: courseId
        )
    }
}

// MARK: - Constants

struct SupabaseConstants {
    static let users = "users"
    static let organizations = "organizations"
    static let courses = "courses"
    static let courseModules = "course_modules"
    static let lessons = "lessons"
    static let enrollments = "enrollments"
    static let lessonProgress = "lesson_progress"
    static let assessments = "assessments"
    static let assessmentQuestions = "assessment_questions"
    static let assessmentSubmissions = "assessment_submissions"
    static let courseAssignments = "course_assignments"
    static let notifications = "notifications"
}
