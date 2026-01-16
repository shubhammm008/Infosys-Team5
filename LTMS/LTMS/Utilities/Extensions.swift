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
    
    // Dark Theme Colors
    static let dashboardBg = LinearGradient(
        colors: [
            Color(red: 12/255, green: 14/255, blue: 28/255),
            Color(red: 18/255, green: 20/255, blue: 40/255)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let dashboardCard = Color(red: 24/255, green: 27/255, blue: 54/255)
    static let dashboardCardAlt = Color(red: 32/255, green: 36/255, blue: 78/255)
    
    static let dashboardTextPrimary = Color.white
    static let dashboardTextSecondary = Color.white.opacity(0.65)
    
    static let accentBlue = Color(red: 88/255, green: 108/255, blue: 255/255)
    static let accentPurple = Color(red: 132/255, green: 100/255, blue: 255/255)
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

// MARK: - View Extensions
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
