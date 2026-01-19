//
//  LTMSApp.swift
//  LTMS
//
//  Created by Shubham Singh on 03/01/26.
//

import SwiftUI

@main
struct LTMSApp: App {
    @StateObject private var authService = SupabaseAuthService.shared
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isAuthenticated, let user = authService.currentUser {
                    // Role-based navigation
                    switch user.role {
                    case .admin:
                        AdminDashboardView()
                            .environmentObject(authService)
                    case .educator:
                        EducatorDashboardView()
                            .environmentObject(authService)
                    case .learner:
                        LearnerDashboardView()
                            .environmentObject(authService)
                    }
                } else {
                    UnifiedAuthView()
                        .environmentObject(authService)
                }
            }
            .preferredColorScheme(themeManager.colorScheme)
        }
    }
}
