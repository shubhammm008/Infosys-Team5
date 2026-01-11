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
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal) // Added padding to the title/description block
                }
                
                Divider()
                
                // Prerequisites Section
                if let prerequisites = course.prerequisites, !prerequisites.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Prerequisites", systemImage: "checkmark.circle")
                            .font(.headline)
                            .foregroundColor(.ltmsPrimary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(prerequisites, id: \.self) { prerequisite in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 6))
                                        .foregroundColor(.secondary)
                                        .padding(.top, 6)
                                    Text(prerequisite)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                }
                
                // Learning Objectives Section
                if let objectives = course.learningObjectives, !objectives.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("What You'll Learn", systemImage: "lightbulb.fill")
                            .font(.headline)
                            .foregroundColor(.ltmsPrimary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(objectives, id: \.self) { objective in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(.yellow)
                                        .padding(.top, 4)
                                    Text(objective)
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                }
                
                // Course Details
                VStack(alignment: .leading, spacing: 16) {
                    Text("Course Details")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        DetailItem(icon: "clock.fill", title: "Duration", value: "\(course.durationHours) hours")
                        DetailItem(icon: "chart.bar.fill", title: "Level", value: course.level.displayName)
                    }
                }
                .padding()
                .background(Color.ltmsCardBackground)
                .cornerRadius(16)
                
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
        .alert("Enrollment Successful!", isPresented: $showEnrollmentSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("You have successfully enrolled in \(course.title)")
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
            updatedAt: Date()
        ))
    }
}
