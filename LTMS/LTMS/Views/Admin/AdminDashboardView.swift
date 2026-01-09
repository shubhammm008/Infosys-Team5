//
//  AdminDashboardView.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import SwiftUI

struct AdminDashboardView: View {
    @StateObject private var authService = AuthService.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            AdminHomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            UserManagementView()
                .tabItem {
                    Label("Users", systemImage: "person.3.fill")
                }
                .tag(1)
            
            CourseManagementView()
                .tabItem {
                    Label("Courses", systemImage: "book.fill")
                }
                .tag(2)
            
            AdminProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
                .tag(3)
        }
        .tint(.ltmsPrimary)
    }
}

// MARK: - Admin Home View

struct AdminHomeView: View {
    @StateObject private var authService = AuthService.shared
    @StateObject private var mockDataService = MockDataService.shared
    @State private var showCreateUser = false
    @State private var showCreateCourse = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Welcome back,")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(authService.currentUser?.firstName ?? "Admin")
                                .font(.title)
                                .fontWeight(.bold)
                        }
                        Spacer()
                        
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.ltmsPrimary)
                    }
                    .padding()
                    .background(Color.ltmsCardBackground)
                    .cornerRadius(16)
                    
                    // Quick Stats
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        StatCard(
                            title: "Total Users",
                            value: "\(mockDataService.getUserStats().total)",
                            icon: "person.3.fill",
                            color: .blue
                        )
                        
                        StatCard(
                            title: "Total Courses",
                            value: "\(mockDataService.getCourses().count)",
                            icon: "book.fill",
                            color: .purple
                        )
                        
                        StatCard(
                            title: "Educators",
                            value: "\(mockDataService.getUserStats().educators)",
                            icon: "person.badge.key.fill",
                            color: .orange
                        )
                        
                        StatCard(
                            title: "Learners",
                            value: "\(mockDataService.getUserStats().learners)",
                            icon: "graduationcap.fill",
                            color: .green
                        )
                    }
                    
                    // Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            QuickActionButton(
                                title: "Create Educator Account",
                                icon: "person.badge.plus",
                                color: .blue
                            ) {
                                showCreateUser = true
                            }
                            
                            QuickActionButton(
                                title: "Create New Course",
                                icon: "plus.circle.fill",
                                color: .purple
                            ) {
                                showCreateCourse = true
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color.ltmsBackground)
            .navigationTitle("Dashboard")
            .sheet(isPresented: $showCreateUser) {
                CreateUserView()
            }
            .sheet(isPresented: $showCreateCourse) {
                CreateCourseView()
            }
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.ltmsCardBackground)
        .cornerRadius(16)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(title)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.ltmsCardBackground)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct AdminProfileView: View {
    @StateObject private var authService = AuthService.shared
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.ltmsPrimary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authService.currentUser?.fullName ?? "")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text(authService.currentUser?.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(authService.currentUser?.role.displayName ?? "")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.ltmsPrimary.opacity(0.2))
                                .foregroundColor(.ltmsPrimary)
                                .cornerRadius(6)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Account") {
                    Button(role: .destructive) {
                        showLogoutAlert = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Profile")
            .alert("Sign Out", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    try? authService.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}

#Preview {
    AdminDashboardView()
}
