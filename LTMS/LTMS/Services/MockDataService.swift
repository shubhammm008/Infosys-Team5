//
//  MockDataService.swift
//  LTMS
//
//  Created by Shubham Singh on 08/01/26.
//

import Foundation
import Combine

@MainActor
class MockDataService: ObservableObject {
    static let shared = MockDataService()
    
    @Published var mockUsers: [User] = []
    @Published var mockCourses: [Course] = []
    
    // Store credentials separately (email -> password mapping)
    private var credentials: [String: String] = [:]
    
    // UserDefaults keys
    private let usersKey = "MockDataService_Users"
    private let credentialsKey = "MockDataService_Credentials"
    
    private init() {
        // Load persisted data or setup default
        loadPersistedData()
    }
    
    private func loadPersistedData() {
        // Try to load from UserDefaults
        if let usersData = UserDefaults.standard.data(forKey: usersKey),
           let credentialsData = UserDefaults.standard.data(forKey: credentialsKey) {
            do {
                mockUsers = try JSONDecoder().decode([User].self, from: usersData)
                credentials = try JSONDecoder().decode([String: String].self, from: credentialsData)
                print("✅ Loaded \(mockUsers.count) users from storage")
                return
            } catch {
                print("⚠️ Failed to load persisted data: \(error)")
            }
        }
        
        // If no persisted data or loading failed, setup default
        setupDefaultData()
    }
    
    private func setupDefaultData() {
        // Add default admin user with fixed credentials
        let adminUser = User(
            id: "admin_001",
            organizationId: "test_org",
            email: "Admin@ltms.test",
            role: .admin,
            firstName: "System",
            lastName: "Admin",
            profilePictureURL: nil,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date(),
            lastLogin: Date()
        )
        mockUsers.append(adminUser)
        // Store admin credentials (fixed)
        credentials["Admin@ltms.test"] = "test1234"
        
        // Save to UserDefaults
        saveData()
    }
    
    private func saveData() {
        do {
            let usersData = try JSONEncoder().encode(mockUsers)
            let credentialsData = try JSONEncoder().encode(credentials)
            UserDefaults.standard.set(usersData, forKey: usersKey)
            UserDefaults.standard.set(credentialsData, forKey: credentialsKey)
            print("💾 Saved \(mockUsers.count) users to storage")
        } catch {
            print("⚠️ Failed to save data: \(error)")
        }
    }
    
    // MARK: - User Operations
    
    func addUser(_ user: User, password: String) {
        print("📝 Adding user to MockDataService:")
        print("   Email: \(user.email)")
        print("   Role: \(user.role.displayName)")
        print("   Name: \(user.fullName)")
        
        mockUsers.append(user)
        // Store credentials
        credentials[user.email] = password
        saveData()
        
        print("   ✅ User added. Total users: \(mockUsers.count)")
    }
    
    func getUsers() -> [User] {
        return mockUsers
    }
    
    func getUsersByRole(_ role: UserRole) -> [User] {
        return mockUsers.filter { $0.role == role }
    }
    
    func deleteUser(id: String) {
        // Remove credentials when deleting user
        if let user = mockUsers.first(where: { $0.id == id }) {
            credentials.removeValue(forKey: user.email)
        }
        mockUsers.removeAll { $0.id == id }
        saveData()
    }
    
    func updateUser(_ user: User) {
        if let index = mockUsers.firstIndex(where: { $0.id == user.id }) {
            mockUsers[index] = user
            saveData()
        }
    }
    
    // MARK: - Authentication
    
    func validateCredentials(email: String, password: String) -> Bool {
        return credentials[email] == password
    }
    
    func getUserByEmail(_ email: String) -> User? {
        return mockUsers.first(where: { $0.email == email })
    }
    
    // MARK: - Course Operations
    
    func addCourse(_ course: Course) {
        mockCourses.append(course)
    }
    
    func getCourses() -> [Course] {
        return mockCourses
    }
    
    func deleteCourse(id: String) {
        mockCourses.removeAll { $0.id == id }
    }
    
    // MARK: - Stats
    
    func getUserStats() -> (total: Int, educators: Int, learners: Int) {
        let total = mockUsers.count
        let educators = mockUsers.filter { $0.role == .educator }.count
        let learners = mockUsers.filter { $0.role == .learner }.count
        return (total, educators, learners)
    }
    
    // MARK: - Debug
    
    func clearAllData() {
        mockUsers.removeAll()
        mockCourses.removeAll()
        credentials.removeAll()
        UserDefaults.standard.removeObject(forKey: usersKey)
        UserDefaults.standard.removeObject(forKey: credentialsKey)
        setupDefaultData()
    }
}
