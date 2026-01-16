//
//  CourseDetailView.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import SwiftUI

struct CourseDetailView: View {
    @StateObject private var authService = SupabaseAuthService.shared
    @Environment(\.dismiss) private var dismiss
    
    let course: Course
    @State private var isEnrolling = false
    @State private var isEnrolled = false
    @State private var showEnrollmentSuccess = false
    @State private var showEnrollmentError = false
    @State private var enrollmentErrorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Course Header
                VStack(alignment: .leading, spacing: 16) {
                    // Thumbnail
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [.accentPrimary, .accentSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 200)
                        .overlay(
                            Image(systemName: "book.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.7))
                        )
                    
                    // Title and Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text(course.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.dashboardTextPrimary)
                        
                        Text(course.courseDescription)
                            .font(.body)
                            .foregroundColor(.dashboardTextSecondary)
                    }
                }
                
                // Course Details
                VStack(alignment: .leading, spacing: 20) {
                    Text("Course Details")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.dashboardTextPrimary)
                    
                    HStack(spacing: 24) {
                        DetailItem(icon: "clock.fill", title: "Duration", value: "\(course.durationHours) hours", color: .blue)
                        
                        Spacer()
                        
                        DetailItem(icon: "chart.bar.fill", title: "Level", value: course.level.displayName, color: .purple)
                    }
                }
                .padding(24)
                .background(Color.dashboardCard)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                
                // Enrollment Button
                if !isEnrolled {
                    Button(action: enrollInCourse) {
                        HStack {
                            if isEnrolling {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Enroll Now")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.accentPrimary, .accentSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    .disabled(isEnrolling)
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("You're enrolled in this course")
                            .fontWeight(.semibold)
                            .foregroundColor(.dashboardTextPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.15))
                    .cornerRadius(14)
                }
            }
            .padding()
        }
        .background(Color.dashboardBg)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task {
            await checkEnrollmentStatus()
        }
        .alert("Enrollment Successful!", isPresented: $showEnrollmentSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("You have successfully enrolled in \(course.title)")
        }
        .alert("Enrollment Error", isPresented: $showEnrollmentError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(enrollmentErrorMessage)
        }
    }
    
    private func checkEnrollmentStatus() async {
        guard let userId = authService.currentUser?.id,
              let courseId = course.id else { return }
        
        do {
            isEnrolled = try await ContentService.shared.isUserEnrolled(learnerId: userId, courseId: courseId)
        } catch {
            print("Error checking enrollment: \(error)")
        }
    }
    
    private func enrollInCourse() {
        guard let userId = authService.currentUser?.id,
              let courseId = course.id else { return }
        
        Task {
            isEnrolling = true
            defer { isEnrolling = false }
            
            do {
                _ = try await ContentService.shared.enrollInCourse(learnerId: userId, courseId: courseId)
                isEnrolled = true
                showEnrollmentSuccess = true
            } catch {
                let errorMessage = "\(error)"
                if errorMessage.contains("23505") || errorMessage.contains("duplicate key") {
                    // User is already enrolled, just update the UI
                    isEnrolled = true
                } else {
                    enrollmentErrorMessage = "Failed to enroll in the course. Please try again."
                    showEnrollmentError = true
                }
                print("Error enrolling: \(error)")
            }
        }
    }
}

struct DetailItem: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon background (smaller)
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 42, height: 42)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.dashboardTextSecondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.dashboardTextPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }
}

#Preview {
    NavigationStack {
        CourseDetailView(course: Course(
            id: "1",
            organizationId: "org1",
            title: "iOS Development with SwiftUI",
            courseDescription: "Learn to build beautiful iOS apps using SwiftUI and modern Swift programming techniques.",
            level: .beginner,
            durationHours: 40,
            thumbnailURL: nil,
            isPublished: true,
            createdById: "user1",
            assignedEducatorId: "educator1",
            createdAt: Date(),
            updatedAt: Date(),
            scheduledStartDate: nil,
            scheduledEndDate: nil,
            enrollmentDeadline: nil,
            maxEnrollments: nil,
            isVisibleInCatalog: true
        ))
    }
}
