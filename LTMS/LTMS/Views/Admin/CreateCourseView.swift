//
//  CreateCourseView.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import SwiftUI
import Combine

struct CreateCourseView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = SupabaseAuthService.shared
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedLevel: CourseLevel = .beginner
    @State private var durationHours = 10
    @State private var isPublished = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
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
                
//                Section("Publishing") {
//                    Toggle("Publish Immediately", isOn: $isPublished)
//                    Toggle("Visible in Catalog", isOn: $isVisibleInCatalog)
//                }
                
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
        }
        .navigationTitle("Create New Course")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(action: { dismiss() }) {
                    Text("Cancel")
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    @ViewBuilder
    private func customTextField(title: String, text: Binding<String>, isMultiline: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.dashboardTextSecondary)
            
            if isMultiline {
                TextEditor(text: text)
                    .scrollContentBackground(.hidden) // Hide default white background
                    .frame(minHeight: 100)
                    .padding(12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .foregroundColor(.dashboardTextPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            } else {
                TextField(title, text: text)
                    .padding(12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .foregroundColor(.dashboardTextPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
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
            
            do {
                let course = Course(
                    id: nil,
                    organizationId: authService.currentUser?.organizationId ?? AppConstants.defaultOrganizationId,
                    title: title,
                    courseDescription: description,
                    level: selectedLevel,
                    durationHours: durationHours,
                    thumbnailURL: nil,
                    isPublished: isPublished,
                    createdById: authService.currentUser?.id ?? "",
                    assignedEducatorId: nil,
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
                
                print("✅ Course created in Supabase successfully!")
                dismiss()
            } catch {
                print("❌ Error creating course: \(error)")
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

#Preview {
    CreateCourseView()
}
