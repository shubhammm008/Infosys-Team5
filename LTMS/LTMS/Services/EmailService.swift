//
//  EmailService.swift
//  LTMS
//
//  Email service to send credentials via Supabase Edge Function
//

import Foundation

class EmailService {
    static let shared = EmailService()
    
    private let functionURL = "https://digypbytkohndsubnuhb.supabase.co/functions/v1/send-educator-credentials"
    
    private init() {}
    
    func sendEducatorCredentials(
        to email: String,
        password: String,
        firstName: String,
        lastName: String
    ) async throws {
        let payload: [String: String] = [
            "email": email,
            "password": password,
            "firstName": firstName,
            "lastName": lastName
        ]
        
        guard let url = URL(string: functionURL) else {
            throw EmailError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.shared.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(SupabaseConfig.shared.anonKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EmailError.invalidResponse
        }
        
        print("📧 Email service response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                print("❌ Email error: \(errorResponse.error)")
                throw EmailError.sendFailed(errorResponse.error)
            }
            let responseString = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Email failed: \(responseString)")
            throw EmailError.sendFailed("HTTP \(httpResponse.statusCode)")
        }
        
        print("✅ Email sent successfully to \(email)")
    }
}

enum EmailError: LocalizedError {
    case invalidURL
    case invalidResponse
    case sendFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid email service URL"
        case .invalidResponse:
            return "Invalid response from email service"
        case .sendFailed(let message):
            return "Failed to send email: \(message)"
        }
    }
}

struct ErrorResponse: Codable {
    let error: String
}
