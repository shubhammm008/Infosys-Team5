//
//  CreateCourseView.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import SwiftUI

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
            .navigationTitle("Create New Course")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(Color.dashboardBg)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.dashboardTextPrimary)
                            .frame(width: 40, height: 40)
                            .background(Color.dashboardCard)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("Create New Course")
                        .font(.headline)
                        .foregroundColor(.dashboardTextPrimary)
                    
                    Spacer()
                    
                    // Invisible spacer for centering
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Course Information Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Course Information")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.dashboardTextSecondary)
                            
                            VStack(spacing: 12) {
                                customTextField(title: "Course Title", text: $title)
                                customTextField(title: "Description", text: $description, isMultiline: true)
                                
                                HStack {
                                    Text("Level")
                                        .foregroundColor(.dashboardTextPrimary)
                                    Spacer()
                                    Picker("Level", selection: $selectedLevel) {
                                        ForEach(CourseLevel.allCases, id: \.self) { level in
                                            Text(level.displayName).tag(level)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(.accentBlue)
                                }
                                
                                customTextField(title: "Duration (Hours)", text: Binding(
                                    get: { String(durationHours) },
                                    set: { durationHours = Int($0) ?? 0 }
                                ))
                                .keyboardType(.numberPad)
                            }
                        }
                        .padding()
                        .background(Color.dashboardCard)
                        .cornerRadius(20)
                        
                        // Publishing Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Publishing")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.dashboardTextSecondary)
                            
                            Toggle("Publish", isOn: $isPublished)
                                .foregroundColor(.dashboardTextPrimary)
                                .tint(.accentBlue)
                            
                            Toggle("Visible in Catalog", isOn: $isVisibleInCatalog)
                                .foregroundColor(.dashboardTextPrimary)
                                .tint(.accentBlue)
                        }
                        .padding()
                        .background(Color.dashboardCard)
                        .cornerRadius(20)
                        
                        // Scheduling Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Course Scheduling")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.dashboardTextSecondary)
                            
                            Toggle("Enable Scheduling", isOn: $enableScheduling)
                                .foregroundColor(.dashboardTextPrimary)
                                .tint(.accentBlue)
                            
                            if enableScheduling {
                                DatePicker("Start Date", selection: $scheduledStartDate, displayedComponents: [.date, .hourAndMinute])
                                    .foregroundColor(.dashboardTextPrimary)
                                    .tint(.accentBlue)
                                
                                DatePicker("End Date", selection: $scheduledEndDate, displayedComponents: [.date, .hourAndMinute])
                                    .foregroundColor(.dashboardTextPrimary)
                                    .tint(.accentBlue)
                                
                                Text("Course will only be available between the start and end dates")
                                    .font(.caption)
                                    .foregroundColor(.dashboardTextSecondary)
                            }
                        }
                        .padding()
                        .background(Color.dashboardCard)
                        .cornerRadius(20)
                        
                        // Enrollment Management Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Enrollment Management")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.dashboardTextSecondary)
                            
                            Toggle("Set Enrollment Deadline", isOn: $enableEnrollmentDeadline)
                                .foregroundColor(.dashboardTextPrimary)
                                .tint(.accentBlue)
                            
                            if enableEnrollmentDeadline {
                                DatePicker("Deadline", selection: $enrollmentDeadline, displayedComponents: [.date, .hourAndMinute])
                                    .foregroundColor(.dashboardTextPrimary)
                                    .tint(.accentBlue)
                            }
                            
                            Toggle("Limit Enrollments", isOn: $enableMaxEnrollments)
                                .foregroundColor(.dashboardTextPrimary)
                                .tint(.accentBlue)
                            
                            if enableMaxEnrollments {
                                customTextField(title: "Max Enrollments", text: Binding(
                                    get: { String(maxEnrollments) },
                                    set: { maxEnrollments = Int($0) ?? 0 }
                                ))
                                .keyboardType(.numberPad)
                                
                                Text("Course enrollment will be closed when limit is reached")
                                    .font(.caption)
                                    .foregroundColor(.dashboardTextSecondary)
                            }
                        }
                        .padding()
                        .background(Color.dashboardCard)
                        .cornerRadius(20)
                        
                        // Create Button
                        Button(action: createCourse) {
                            ZStack {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Create Course")
                                        .fontWeight(.bold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [Color.accentBlue, Color.accentPurple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(color: Color.accentBlue.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .disabled(isLoading || !isFormValid)
                        .opacity(isFormValid ? 1.0 : 0.6)
                        .padding(.bottom, 20)
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
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
