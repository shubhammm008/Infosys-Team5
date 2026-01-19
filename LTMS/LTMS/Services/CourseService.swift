//
//  CourseService.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import Foundation
import Combine
import PostgREST
import Supabase

@MainActor
class CourseService: ObservableObject {
    static let shared = CourseService()
    
    @Published var courses: [Course] = []
    @Published var isLoading = false
    
    private init() {}
    
    // MARK: - Course Operations (Supabase)
    
    func createCourse(_ course: Course) async throws -> Course {
        return try await SupabaseService.shared.create(course, in: SupabaseConstants.courses)
    }
    
    func updateCourse(_ course: Course) async throws {
        guard let id = course.id else { return }
        let _: Course = try await SupabaseService.shared.update(course, id: id, in: SupabaseConstants.courses)
    }
    
    func deleteCourse(id: String) async throws {
        try await SupabaseService.shared.delete(id: id, from: SupabaseConstants.courses)
    }
    
    func fetchCourse(id: String) async throws -> Course {
        return try await SupabaseService.shared.fetch(id: id, from: SupabaseConstants.courses)
    }
    
    func fetchAllCourses() async throws {
        isLoading = true
        defer { isLoading = false }
        courses = try await SupabaseService.shared.fetchAll(from: SupabaseConstants.courses)
    }
    
    func fetchCoursesByOrganization(organizationId: String) async throws -> [Course] {
        return try await SupabaseService.shared.query(
            from: SupabaseConstants.courses,
            where: "organization_id",
            equals: organizationId
        )
    }
    
    func fetchCoursesByEducator(educatorId: String) async throws -> [Course] {
        return try await SupabaseService.shared.query(
            from: SupabaseConstants.courses,
            where: "assigned_educator_id",
            equals: educatorId
        )
    }
    
    func fetchPublishedCourses() async throws -> [Course] {
        return try await SupabaseService.shared.fetchPublishedCourses(in: AppConstants.defaultOrganizationId)
    }
    
    func fetchPublishedCourses(for organizationId: String) async throws -> [Course] {
        return try await SupabaseService.shared.fetchPublishedCourses(in: organizationId)
    }
    
    func fetchAllPublishedCourses() async throws -> [Course] {
        return try await SupabaseService.shared.fetchAllPublishedCourses()
    }
    
    func fetchPendingCourses(organizationId: String) async throws -> [Course] {
        let response = try await SupabaseService.shared.client
            .from(SupabaseConstants.courses)
            .select()
            .eq("organization_id", value: organizationId)
            .eq("is_published", value: false)
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Course].self, from: response.data)
    }
    
    func publishCourse(courseId: String) async throws {
        var course = try await fetchCourse(id: courseId)
        course.isPublished = true
        course.updatedAt = Date()
        try await updateCourse(course)
        print("✅ Course '\(course.title)' has been published")
    }
    
    // MARK: - Module Operations (Supabase)
    
    func createModule(_ module: Module) async throws -> Module {
        return try await SupabaseService.shared.create(module, in: SupabaseConstants.courseModules)
    }
    
    func fetchModulesByCourse(courseId: String) async throws -> [Module] {
        let response = try await SupabaseService.shared.client
            .from(SupabaseConstants.courseModules)
            .select()
            .eq("course_id", value: courseId)
            .order("order_index")
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Module].self, from: response.data)
    }
    
    func updateModule(_ module: Module) async throws {
        guard let id = module.id else { return }
        let _: Module = try await SupabaseService.shared.update(module, id: id, in: SupabaseConstants.courseModules)
    }
    
    func deleteModule(id: String) async throws {
        try await SupabaseService.shared.delete(id: id, from: SupabaseConstants.courseModules)
    }
    
    // MARK: - Lesson Operations (Supabase)
    
    func createLesson(_ lesson: Lesson) async throws -> Lesson {
        return try await SupabaseService.shared.create(lesson, in: SupabaseConstants.lessons)
    }
    
    func fetchLessonsByModule(moduleId: String) async throws -> [Lesson] {
        let response = try await SupabaseService.shared.client
            .from(SupabaseConstants.lessons)
            .select()
            .eq("module_id", value: moduleId)
            .order("order_index")
            .execute()
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Lesson].self, from: response.data)
    }
    
    func updateLesson(_ lesson: Lesson) async throws {
        guard let id = lesson.id else { return }
        let _: Lesson = try await SupabaseService.shared.update(lesson, id: id, in: SupabaseConstants.lessons)
    }
    
    func deleteLesson(id: String) async throws {
        try await SupabaseService.shared.delete(id: id, from: SupabaseConstants.lessons)
    }
}
