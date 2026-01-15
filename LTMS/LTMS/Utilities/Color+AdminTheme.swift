//
//  Color+AdminTheme.swift
//  LTMS
//
//  Created by Assistant on 16/01/26.
//

import SwiftUI

extension Color {

    // MARK: - Dark Theme
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
    
    // MARK: - Legacy Compatibility Aliases (Mapped to new theme)
    static let accentPrimary = accentBlue
    static let accentSecondary = accentPurple
    static let accentSuccess = accentBlue // Mapped to Blue for consistency in limited palette
    static let accentWarning = accentPurple // Mapped to Purple for consistency
    static let accentHighlight = accentPurple.opacity(0.3)
    static let textOnAccent = dashboardTextPrimary
}

// MARK: - Hex Support
extension Color {
    init(hex: String) {
        let hex = hex.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)

        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}
