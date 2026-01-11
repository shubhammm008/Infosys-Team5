//
//  CourseService.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import Foundation
import Combine

@MainActor
class CourseService: ObservableObject {
    static let shared = CourseService()
    // private let db = Firestore.firestore() // Disabled for Supabase migration
    
    @Published var courses: [Course] = []
    @Published var isLoading = false
    
    private init() {}
    
    // MARK: - Course Operations
    
    func createCourse(_ course: Course) async throws -> String {
        return try await FirebaseService.shared.create(course, in: FirebaseConstants.courses)
    }
    
    func updateCourse(_ course: Course) async throws {
        guard let id = course.id else { return }
        try await FirebaseService.shared.update(course, id: id, in: FirebaseConstants.courses)
    }
    
    func deleteCourse(id: String) async throws {
        try await FirebaseService.shared.delete(id: id, from: FirebaseConstants.courses)
    }
    
    func fetchCourse(id: String) async throws -> Course {
        return try await FirebaseService.shared.fetch(id: id, from: FirebaseConstants.courses)
    }
    
    func fetchAllCourses() async throws {
        isLoading = true
        defer { isLoading = false }
        courses = try await FirebaseService.shared.fetchAll(from: FirebaseConstants.courses)
    }
    
    func fetchCoursesByOrganization(organizationId: String) async throws -> [Course] {
        return try await FirebaseService.shared.query(
            from: FirebaseConstants.courses,
            where: "organizationId",
            isEqualTo: organizationId
        )
    }
    
    func fetchCoursesByEducator(educatorId: String) async throws -> [Course] {
        return try await FirebaseService.shared.query(
            from: FirebaseConstants.courses,
            where: "assignedEducatorId",
            isEqualTo: educatorId
        )
    }
    
    func fetchPublishedCourses() async throws -> [Course] {
        return try await FirebaseService.shared.query(
            from: FirebaseConstants.courses,
            where: "isPublished",
            isEqualTo: true
        )
    }
    
    // MARK: - Module Operations
    
    func createModule(_ module: Module) async throws -> String {
        return try await FirebaseService.shared.create(module, in: FirebaseConstants.modules)
    }
    
    func fetchModulesByCourse(courseId: String) async throws -> [Module] {
        let modules: [Module] = try await FirebaseService.shared.query(
            from: FirebaseConstants.modules,
            where: "courseId",
            isEqualTo: courseId
        )
        return modules.sorted { $0.orderIndex < $1.orderIndex }
    }
    
    func updateModule(_ module: Module) async throws {
        guard let id = module.id else { return }
        try await FirebaseService.shared.update(module, id: id, in: FirebaseConstants.modules)
    }
    
    func deleteModule(id: String) async throws {
        try await FirebaseService.shared.delete(id: id, from: FirebaseConstants.modules)
    }
    
    // MARK: - Lesson Operations
    
    func createLesson(_ lesson: Lesson) async throws -> String {
        return try await FirebaseService.shared.create(lesson, in: FirebaseConstants.lessons)
    }
    
    func fetchLessonsByModule(moduleId: String) async throws -> [Lesson] {
        let lessons: [Lesson] = try await FirebaseService.shared.query(
            from: FirebaseConstants.lessons,
            where: "moduleId",
            isEqualTo: moduleId
        )
        return lessons.sorted { $0.orderIndex < $1.orderIndex }
    }
    
    func updateLesson(_ lesson: Lesson) async throws {
        guard let id = lesson.id else { return }
        try await FirebaseService.shared.update(lesson, id: id, in: FirebaseConstants.lessons)
    }
    
    func deleteLesson(id: String) async throws {
        try await FirebaseService.shared.delete(id: id, from: FirebaseConstants.lessons)
    }
}
