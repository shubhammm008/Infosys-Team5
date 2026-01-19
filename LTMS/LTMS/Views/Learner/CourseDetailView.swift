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
                                colors: [.ltmsPrimary, .ltmsSecondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 200)
                        .overlay(
                            Image(systemName: "book.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.8))
                        )
                    
                    // Title and Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text(course.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(course.courseDescription)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Course Details
                VStack(alignment: .leading, spacing: 16) {
                    Text("Course Details")
                        .font(.headline)
                    
                    HStack {
                        DetailItem(icon: "clock.fill", title: "Duration", value: "\(course.durationHours) hours")
                        Spacer()
                        DetailItem(icon: "chart.bar.fill", title: "Level", value: course.level.displayName)
                            .padding(.trailing, 28) // Balance the icon width on the left
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.ltmsCardBackground)
                
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
                                colors: [.ltmsPrimary, .ltmsSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isEnrolling)
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("You're enrolled in this course")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .background(Color.ltmsBackground)
        .navigationBarTitleDisplayMode(.inline)
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
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.ltmsPrimary)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
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
