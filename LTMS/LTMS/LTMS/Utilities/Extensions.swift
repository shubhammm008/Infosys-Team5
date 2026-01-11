//
//  Extensions.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import Foundation
import SwiftUI

// MARK: - Date Extensions
extension Date {
    func formatted(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
    func timeAgo() -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .weekOfYear, .day, .hour, .minute], from: self, to: now)
        
        if let year = components.year, year > 0 {
            return "\(year) year\(year == 1 ? "" : "s") ago"
        }
        if let month = components.month, month > 0 {
            return "\(month) month\(month == 1 ? "" : "s") ago"
        }
        if let week = components.weekOfYear, week > 0 {
            return "\(week) week\(week == 1 ? "" : "s") ago"
        }
        if let day = components.day, day > 0 {
            return "\(day) day\(day == 1 ? "" : "s") ago"
        }
        if let hour = components.hour, hour > 0 {
            return "\(hour) hour\(hour == 1 ? "" : "s") ago"
        }
        if let minute = components.minute, minute > 0 {
            return "\(minute) minute\(minute == 1 ? "" : "s") ago"
        }
        return "Just now"
    }
}

// MARK: - Color Extensions
extension Color {
    static let ltmsPrimary = Color.blue
    static let ltmsSecondary = Color.purple
    static let ltmsAccent = Color.orange
    static let ltmsBackground = Color(.systemGroupedBackground)
    static let ltmsCardBackground = Color(.secondarySystemGroupedBackground)
}

// MARK: - String Extensions
extension String {
    // Validate any proper email format - accepts any domain
    var isValidEmail: Bool {
        // Basic email validation - accepts any valid email format
        // Format: localpart@domain.tld
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    
    // Flexible validation for admin-created users - any valid email format
    var isValidEmailFormat: Bool {
        // Basic email validation - accepts any valid email format
        // Format: localpart@domain.tld
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
}
