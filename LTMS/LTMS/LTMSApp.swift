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
    
    var body: some Scene {
        WindowGroup {
            if authService.isAuthenticated, let user = authService.currentUser {
                // Role-based navigation
                switch user.role {
                case .admin:
                    AdminDashboardView()
                case .educator:
                    EducatorDashboardView()
                case .learner:
                    LearnerDashboardView()
                }
            } else {
                UnifiedAuthView()
            }
        }
    }
}
