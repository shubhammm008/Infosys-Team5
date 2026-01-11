//
//  FirebaseService.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

class FirebaseService {
    static let shared = FirebaseService()
    // let db = Firestore.firestore() // DISABLED - Migrated to Supabase
    // let auth = Auth.auth() // DISABLED - Migrated to Supabase
    
    private init() {
        // Configure Firestore settings
        // let settings = FirestoreSettings()
        // settings.cacheSettings = PersistentCacheSettings()
        // db.settings = settings
    }
    
    // MARK: - Generic Firestore Operations
    // ALL METHODS DISABLED - Migrated to Supabase
    
    func create<T: Codable>(_ item: T, in collection: String) async throws -> String {
        fatalError("FirebaseService is disabled - use SupabaseService instead")
    }
    
    func update<T: Codable>(_ item: T, id: String, in collection: String) async throws {
        fatalError("FirebaseService is disabled - use SupabaseService instead")
    }
    
    func delete(id: String, from collection: String) async throws {
        fatalError("FirebaseService is disabled - use SupabaseService instead")
    }
    
    func fetch<T: Codable>(id: String, from collection: String) async throws -> T {
        fatalError("FirebaseService is disabled - use SupabaseService instead")
    }
    
    func fetchAll<T: Codable>(from collection: String) async throws -> [T] {
        fatalError("FirebaseService is disabled - use SupabaseService instead")
    }
    
    func query<T: Codable>(
        from collection: String,
        where field: String,
        isEqualTo value: Any
    ) async throws -> [T] {
        fatalError("FirebaseService is disabled - use SupabaseService instead")
    }
}
