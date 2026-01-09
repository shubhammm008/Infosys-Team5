//
//  LTMSApp.swift
//  LTMS
//
//  Created by Shubham Singh on 03/01/26.
//

import SwiftUI
import Supabase

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Initialize Supabase client
        _ = SupabaseService.shared
        return true
    }
}

@main
struct LTMSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authService = AuthService.shared
    
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

