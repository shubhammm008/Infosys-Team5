//
//  SupabaseConfig.swift
//  LTMS
//
//  Created for Supabase Integration
//

import Foundation
import Supabase

enum SupabaseConfigError: LocalizedError {
    case missingPlist
    case missingKey(String)
    case invalidURL
    
    var errorDescription: String? {
        switch self {
        case .missingPlist:
            return "Supabase-Info.plist not found. Please create it with your Supabase credentials."
        case .missingKey(let key):
            return "Missing key '\(key)' in Supabase-Info.plist"
        case .invalidURL:
            return "Invalid Supabase URL in configuration"
        }
    }
}

class SupabaseConfig {
    static let shared = SupabaseConfig()
    
    let client: SupabaseClient
    private let configuredURL: String
    
    private init() {
        // Try to load from Supabase-Info.plist
        guard let path = Bundle.main.path(forResource: "Supabase-Info", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path) else {
            // Fallback to test configuration for development
            print("⚠️ Supabase-Info.plist not found, using test mode")
            self.configuredURL = "https://placeholder.supabase.co"
            self.client = SupabaseClient(
                supabaseURL: URL(string: self.configuredURL)!,
                supabaseKey: "placeholder-key"
            )
            return
        }
        
        guard let urlString = config["SUPABASE_URL"] as? String else {
            fatalError(SupabaseConfigError.missingKey("SUPABASE_URL").localizedDescription)
        }
        
        guard let anonKey = config["SUPABASE_ANON_KEY"] as? String else {
            fatalError(SupabaseConfigError.missingKey("SUPABASE_ANON_KEY").localizedDescription)
        }
        
        guard let url = URL(string: urlString) else {
            fatalError(SupabaseConfigError.invalidURL.localizedDescription)
        }
        
        // Initialize Supabase client
        self.configuredURL = urlString
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: anonKey
        )
        
        print("✅ Supabase configured successfully")
        print("📍 URL: \(urlString)")
    }
    
    // Helper to check if Supabase is properly configured
    var isConfigured: Bool {
        return configuredURL != "https://placeholder.supabase.co"
    }
}
