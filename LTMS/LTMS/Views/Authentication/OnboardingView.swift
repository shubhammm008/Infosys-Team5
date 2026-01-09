//
//  OnboardingView.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import SwiftUI

struct OnboardingView: View {
    @State private var selectedUserType: UserType?
    
    enum UserType {
        case admin
        case educator
        case learner
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color.ltmsPrimary.opacity(0.1),
                        Color.ltmsSecondary.opacity(0.05),
                        Color.ltmsBackground
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    // Header Section
                    VStack(spacing: 16) {
                        Image(systemName: "graduationcap.circle.fill")
                            .font(.system(size: 100))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.ltmsPrimary, .ltmsSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .ltmsPrimary.opacity(0.3), radius: 20, x: 0, y: 10)
                        
                        Text("Welcome to LTMS")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Learning & Training Management System")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 60)
                    
                    // User Type Selection Cards
                    VStack(spacing: 20) {
                        Text("Choose Your Role")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        // Admin Card
                        UserTypeCard(
                            icon: "person.badge.key.fill",
                            title: "Admin",
                            description: "Manage the entire system",
                            gradient: [Color.purple, Color.purple.opacity(0.7)],
                            action: {
                                selectedUserType = .admin
                            }
                        )
                        
                        // Educator Card
                        UserTypeCard(
                            icon: "person.fill.checkmark",
                            title: "Educator",
                            description: "Create and manage courses",
                            gradient: [Color.ltmsPrimary, Color.ltmsSecondary],
                            action: {
                                selectedUserType = .educator
                            }
                        )
                        
                        // Learner Card
                        UserTypeCard(
                            icon: "person.fill.viewfinder",
                            title: "Learner",
                            description: "Access courses and learn",
                            gradient: [Color.green, Color.teal],
                            action: {
                                selectedUserType = .learner
                            }
                        )
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                }
            }
            .navigationDestination(isPresented: Binding(
                get: { selectedUserType == .admin },
                set: { if !$0 { selectedUserType = nil } }
            )) {
                AdminLoginView()
            }
            .navigationDestination(isPresented: Binding(
                get: { selectedUserType == .educator },
                set: { if !$0 { selectedUserType = nil } }
            )) {
                RoleBasedAuthView(role: .educator)
            }
            .navigationDestination(isPresented: Binding(
                get: { selectedUserType == .learner },
                set: { if !$0 { selectedUserType = nil } }
            )) {
                RoleBasedAuthView(role: .learner)
            }
        }
    }
}

// MARK: - User Type Card Component
struct UserTypeCard: View {
    let icon: String
    let title: String
    let description: String
    let gradient: [Color]
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                        .shadow(color: gradient[0].opacity(0.4), radius: 10, x: 0, y: 5)
                    
                    Image(systemName: icon)
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
                
                // Text Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.ltmsCardBackground)
                    .shadow(color: Color.black.opacity(0.1), radius: isPressed ? 5 : 15, x: 0, y: isPressed ? 2 : 8)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
}

#Preview {
    OnboardingView()
}
