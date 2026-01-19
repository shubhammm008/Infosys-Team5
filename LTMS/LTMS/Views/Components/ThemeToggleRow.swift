//
//  ThemeToggleRow.swift
//  LTMS
//
//  Created for Light/Dark Mode Feature
//

import SwiftUI

struct ThemeToggleRow: View {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        Picker("Theme", selection: $themeManager.selectedTheme) {
            ForEach(AppTheme.allCases, id: \.self) { theme in
                Label(theme.displayName, systemImage: theme.icon)
                    .tag(theme)
            }
        }
        .pickerStyle(.menu)
    }
}
