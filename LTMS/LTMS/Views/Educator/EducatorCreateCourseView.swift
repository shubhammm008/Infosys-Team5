//
//  EducatorCreateCourseView.swift
//  LTMS
//
//  Created for Educator Course Creation
//

import SwiftUI
import Combine

struct EducatorCreateCourseView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = SupabaseAuthService.shared
    
    var onCourseCreated: () -> Void
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedLevel: CourseLevel = .beginner
    @State private var durationHours = 10
    @State private var isPublished = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    // Scheduling fields
    @State private var enableScheduling = false
    @State private var scheduledStartDate = Date()
    @State private var scheduledEndDate = Date().addingTimeInterval(86400 * 30) // 30 days later
    @State private var enableEnrollmentDeadline = false
    @State private var enrollmentDeadline = Date().addingTimeInterval(86400 * 7) // 7 days later
    
    // Enrollment management
    @State private var enableMaxEnrollments = false
    @State private var maxEnrollments = 50
    @State private var isVisibleInCatalog = true
    
    @State private var showStartDatePicker = false
    @State private var showEndDatePicker = false
    @State private var showDeadlinePicker = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Course Information") {
                    TextField("Course Title", text: $title)
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Picker("Level", selection: $selectedLevel) {
                        ForEach(CourseLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                    
                    HStack {
                        Text("Duration (hours)")
                        Spacer()
                        TextField("Hours", value: $durationHours, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Stepper("Duration", value: $durationHours, in: 1...500)
                            .labelsHidden()
                    }
                }
                
                Section {
                    Toggle("Enable Scheduling", isOn: $enableScheduling)
                    
                    if enableScheduling {
                        Button {
                            showStartDatePicker = true
                        } label: {
                            HStack {
                                Text("Start Date")
                                Spacer()
                                Text(dateTimeFormatter.string(from: scheduledStartDate))
                                    .foregroundColor(.dashboardTextSecondary)
                            }
                        }
                        .sheet(isPresented: $showStartDatePicker) {
                            NavigationStack {
                                DatePicker(
                                    "Start Date",
                                    selection: $scheduledStartDate,
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .datePickerStyle(.graphical)
                                .padding()
                                .navigationTitle("Start Date")
                                .toolbar {
                                    ToolbarItem(placement: .confirmationAction) {
                                        Button("Done") {
                                            if scheduledEndDate < scheduledStartDate {
                                                scheduledEndDate = scheduledStartDate
                                            }
                                            showStartDatePicker = false
                                        }
                                    }
                                }
                            }
                        }
                        
                        Button {
                            showEndDatePicker = true
                        } label: {
                            HStack {
                                Text("End Date")
                                Spacer()
                                Text(dateTimeFormatter.string(from: scheduledEndDate))
                                    .foregroundColor(.dashboardTextSecondary)
                            }
                        }
                        .sheet(isPresented: $showEndDatePicker) {
                            NavigationStack {
                                DatePicker(
                                    "End Date",
                                    selection: $scheduledEndDate,
                                    in: scheduledStartDate...,
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .datePickerStyle(.graphical)
                                .padding()
                                .navigationTitle("End Date")
                                .toolbar {
                                    ToolbarItem(placement: .confirmationAction) {
                                        Button("Done") {
                                            showEndDatePicker = false
                                        }
                                    }
                                }
                            }
                        }
                    }
                } header: {
                    Text("Course Scheduling")
                } footer: {
                    if enableScheduling {
                        Text("Course will only be available between the start and end dates")
                    }
                }
                
                Section {
                    Toggle("Set Enrollment Deadline", isOn: $enableEnrollmentDeadline)
                    
                    if enableEnrollmentDeadline {
                        Button {
                            showDeadlinePicker = true
                        } label: {
                            HStack {
                                Text("Deadline")
                                Spacer()
                                Text(dateTimeFormatter.string(from: enrollmentDeadline))
                                    .foregroundColor(.dashboardTextSecondary)
                            }
                        }
                        .sheet(isPresented: $showDeadlinePicker) {
                            NavigationStack {
                                DatePicker(
                                    "Deadline",
                                    selection: $enrollmentDeadline,
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .datePickerStyle(.graphical)
                                .padding()
                                .navigationTitle("Enrollment Deadline")
                                .toolbar {
                                    ToolbarItem(placement: .confirmationAction) {
                                        Button("Done") {
                                            showDeadlinePicker = false
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    Toggle("Limit Enrollments", isOn: $enableMaxEnrollments)
                    
                    if enableMaxEnrollments {
                        HStack {
                            Text("Max Enrollments")
                            Spacer()
                            TextField("Max", value: $maxEnrollments, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                            Stepper("Max Enrollments", value: $maxEnrollments, in: 1...1000)
                                .labelsHidden()
                        }
                    }
                } header: {
                    Text("Enrollment Management")
                } footer: {
                    if enableMaxEnrollments {
                        Text("Course enrollment will be closed when limit is reached")
                    }
                }
                
                Section {
                    Button(action: createCourse) {
                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            Text("Create Course")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isLoading || !isFormValid)
                }
            }
            .navigationTitle("Create New Course")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(Color.dashboardBg)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("Course Submitted!", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your course has been submitted for admin approval. Once approved, it will be visible to learners.")
            }
        }
    }
    
    private var dateTimeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "dd MMM yyyy, HH:mm"
        return formatter
    }
    
    private var isFormValid: Bool {
        !title.isEmpty && !description.isEmpty
    }
    
    private func createCourse() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            guard let currentUser = authService.currentUser else {
                errorMessage = "User not authenticated"
                showError = true
                return
            }
            
            do {
                let course = Course(
                    id: nil,
                    organizationId: currentUser.organizationId ?? AppConstants.defaultOrganizationId,
                    title: title,
                    courseDescription: description,
                    level: selectedLevel,
                    durationHours: durationHours,
                    thumbnailURL: nil,
                    isPublished: false, // ⚠️ Course starts as unpublished, needs admin approval
                    createdById: currentUser.id ?? "",
                    assignedEducatorId: currentUser.id, // Auto-assign to self
                    prerequisites: nil,
                    learningObjectives: nil,
                    createdAt: Date(),
                    updatedAt: Date(),
                    scheduledStartDate: enableScheduling ? scheduledStartDate : nil,
                    scheduledEndDate: enableScheduling ? scheduledEndDate : nil,
                    enrollmentDeadline: enableEnrollmentDeadline ? enrollmentDeadline : nil,
                    maxEnrollments: enableMaxEnrollments ? maxEnrollments : nil,
                    isVisibleInCatalog: isVisibleInCatalog
                )
                
                // Save to Supabase
                _ = try await SupabaseService.shared.create(course, in: SupabaseConstants.courses)
                
                print("✅ Course created successfully by educator!")
                print("   - Created by: \(currentUser.fullName)")
                print("   - Course: \(title)")
                print("   - Status: Pending admin approval")
                print("   - Auto-assigned to: \(currentUser.fullName)")
                
                onCourseCreated()
                showSuccess = true // Show success alert instead of dismissing
            } catch {
                print("❌ Error creating course: \(error)")
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

#Preview {
    EducatorCreateCourseView(onCourseCreated: {})
}
