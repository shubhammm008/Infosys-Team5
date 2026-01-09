//
//  SupabaseService.swift
//  LTMS
//
//  Created on 1/8/26.
//

import Foundation
import Supabase

// Helper to make JSON dictionaries encodable
struct JSONValue: Codable {
    let value: [String: Any]
    
    init(_ value: [String: Any]) {
        self.value = value
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let data = try JSONSerialization.data(withJSONObject: value)
        let string = String(data: data, encoding: .utf8) ?? "{}"
        try container.encode(string)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        let data = string.data(using: .utf8) ?? Data()
        self.value = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
    }
}

class SupabaseService {
    static let shared = SupabaseService()
    
    let client: SupabaseClient
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    private init() {
        // Configure custom JSON encoder/decoder
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // Initialize Supabase client
        client = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.url)!,
            supabaseKey: SupabaseConfig.anonKey
        )
    }
    
    // MARK: - Generic CRUD Operations
    
    /// Create a new item in the specified table
    func create<T: Codable>(_ item: T, in table: String) async throws -> String {
        let response = try await client.database
            .from(table)
            .insert(item)
            .select()
            .execute()
        
        let decoded = try decoder.decode([T].self, from: response.data)
        
        guard let created = decoded.first,
              let mirror = Mirror(reflecting: created).children.first(where: { $0.label == "id" }),
              let id = mirror.value as? String else {
            throw SupabaseError.invalidResponse
        }
        
        return id
    }
    
    /// Update an existing item
    func update<T: Codable>(_ item: T, id: String, in table: String) async throws {
        _ = try await client.database
            .from(table)
            .update(item)
            .eq("id", value: id)
            .execute()
    }
    
    /// Delete an item by ID
    func delete(id: String, from table: String) async throws {
        _ = try await client.database
            .from(table)
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    /// Fetch a single item by ID
    func fetch<T: Codable>(id: String, from table: String) async throws -> T {
        let response = try await client.database
            .from(table)
            .select()
            .eq("id", value: id)
            .single()
            .execute()
        
        return try decoder.decode(T.self, from: response.data)
    }
    
    /// Fetch all items from a table
    func fetchAll<T: Codable>(from table: String) async throws -> [T] {
        let response = try await client.database
            .from(table)
            .select()
            .execute()
        
        return try decoder.decode([T].self, from: response.data)
    }
    
    /// Query items with a single equality filter
    func query<T: Codable>(
        from table: String,
        where field: String,
        isEqualTo value: String
    ) async throws -> [T] {
        let response = try await client.database
            .from(table)
            .select()
            .eq(field, value: value)
            .execute()
        
        return try decoder.decode([T].self, from: response.data)
    }
    
    /// Query items with boolean filter
    func query<T: Codable>(
        from table: String,
        where field: String,
        isEqualTo value: Bool
    ) async throws -> [T] {
        let response = try await client.database
            .from(table)
            .select()
            .eq(field, value: value)
            .execute()
        
        return try decoder.decode([T].self, from: response.data)
    }
    
    /// Query items with multiple filters and sorting
    func query<T: Codable>(
        from table: String,
        filters: [(field: String, value: String)],
        orderBy: String? = nil,
        ascending: Bool = true
    ) async throws -> [T] {
        // Start with the base query
        var queryBuilder = client.database
            .from(table)
            .select()
        
        // Apply all filters by chaining
        for filter in filters {
            queryBuilder = queryBuilder.eq(filter.field, value: filter.value)
        }
        
        // Apply sorting and execute - must be done together
        let response = if let orderBy = orderBy {
            try await queryBuilder
                .order(orderBy, ascending: ascending)
                .execute()
        } else {
            try await queryBuilder
                .execute()
        }
        
        return try decoder.decode([T].self, from: response.data)
    }
}

// MARK: - Custom Errors

enum SupabaseError: LocalizedError {
    case invalidResponse
    case notFound
    case encodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Supabase"
        case .notFound:
            return "Item not found"
        case .encodingError:
            return "Failed to encode data"
        }
    }
}
