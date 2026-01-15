//
//  Color+AdminTheme.swift
//  LTMS
//
//  Created by Assistant on 16/01/26.
//

import SwiftUI

extension Color {

    // MARK: - Backgrounds
    // Soft academic paper tone
    static let dashboardBg = LinearGradient(
        colors: [
            Color(hex: "#FBF6F3"), // warm off-white
            Color(hex: "#F2E9E6")  // subtle cream
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - Card Surfaces
    static let dashboardCard = Color(hex: "#ffffff")      // reading surface (warm off-white)
    static let dashboardCardAlt = Color(hex: "#F7EFEA")   // grouped sections

    // MARK: - Text
    static let dashboardTextPrimary = Color(hex: "#2B1E1E")   // deep wine-black
    static let dashboardTextSecondary = Color(hex: "#6B4A4A") // muted maroon

    // MARK: - Brand Accents (from design you shared)
    static let accentPrimary = Color(hex: "#7A2E3A")   // main maroon
    static let accentSecondary = Color(hex: "#9C4A55") // lighter wine

    // MARK: - Status
    static let accentSuccess = Color(hex: "#4F8A6F")   // calm green
    static let accentWarning = Color(hex: "#C08A5A")   // warm alert
    static let accentHighlight = Color(hex: "#F2E0D8") // subtle emphasis

    // MARK: - Text Utils
    static let textOnAccent = Color(hex: "#FEF8F4") // warm white for dark backgrounds
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
