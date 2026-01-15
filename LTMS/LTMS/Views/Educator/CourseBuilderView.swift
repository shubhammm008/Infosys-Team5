//
//  CourseBuilderView.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import SwiftUI
import Combine

@MainActor
class CourseBuilderViewModel: ObservableObject {
    @Published var modules: [Module] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    let course: Course
    
    init(course: Course) {
        self.course = course
    }
    
    func loadModules() async {
        guard let courseId = course.id else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            modules = try await CourseService.shared.fetchModulesByCourse(courseId: courseId)
            print("✅ Loaded \(modules.count) modules")
        } catch {
            print("❌ Error loading modules: \(error)")
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func createModule(title: String, description: String) async throws {
        guard let courseId = course.id else {
            print("❌ No course ID")
            return
        }
        
        print("📝 Creating module: \(title)")
        
        let module = Module(
            id: nil,
            courseId: courseId,
            title: title,
            moduleDescription: description,
            orderIndex: modules.count,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        do {
            let created = try await CourseService.shared.createModule(module)
            print("✅ Module created with ID: \(created.id ?? "unknown")")
            await loadModules()
        } catch {
            print("❌ Error creating module: \(error)")
            errorMessage = "Failed to create module: \(error.localizedDescription)"
            showError = true
            throw error
        }
    }
}

// MARK: - Course Builder
struct CourseBuilderView: View {
    @StateObject private var viewModel: CourseBuilderViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showAddModule = false
    @State private var showCourseDetails = false
    
    init(course: Course) {
        _viewModel = StateObject(wrappedValue: CourseBuilderViewModel(course: course))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.dashboardBg.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Header
                    HStack {
                        Button {
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
                        
                        Text("Course Builder")
                            .font(.headline)
                            .foregroundColor(.dashboardTextPrimary)
                        
                        Spacer()
                        
                        Button {
                            showCourseDetails = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.accentBlue)
                                .frame(width: 40, height: 40)
                                .background(Color.dashboardCard)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Course Info Card
                            courseInfoCard
                            
                            // Action Cards Section
                            actionCardsSection
                            
                            // Modules Section
                            modulesSection
                        }
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddModule) {
                AddModuleView(viewModel: viewModel)
            }
            .sheet(isPresented: $showCourseDetails) {
                CourseDetailsEditView(course: viewModel.course) {
                    // Refresh if needed
                }
            }
            .task {
                await viewModel.loadModules()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
        }
    }
    
    // MARK: - Course Info Card
    
    private var courseInfoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.course.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.dashboardTextPrimary)
            
            Text(viewModel.course.courseDescription)
                .font(.subheadline)
                .foregroundColor(.dashboardTextSecondary)
            
            HStack(spacing: 12) {
                Label("\(viewModel.course.durationHours)h", systemImage: "clock")
                Text(viewModel.course.level.displayName)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentBlue.opacity(0.2))
                    .foregroundColor(.accentBlue)
                    .cornerRadius(6)
            }
            .font(.caption)
            .foregroundColor(.dashboardTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.dashboardCard)
        .cornerRadius(20)
    }
    
    // MARK: - Action Cards Section
    
    private var actionCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.dashboardTextSecondary)
            
            // Add Module Card
            Button {
                showAddModule = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Add Module")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.dashboardTextPrimary)
                        Text("Create new module with lessons")
                            .font(.caption)
                            .foregroundColor(.dashboardTextSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentBlue)
                }
                .padding()
                .background(Color.dashboardCard)
                .cornerRadius(16)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Modules Section
    
    private var modulesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Modules")
                    .font(.headline)
                    .foregroundColor(.dashboardTextSecondary)
                Spacer()
                Text("\(viewModel.modules.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentBlue.opacity(0.2))
                    .foregroundColor(.accentBlue)
                    .cornerRadius(6)
            }
            
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .tint(.accentBlue)
                    Spacer()
                }
                .padding(.vertical, 40)
            } else if viewModel.modules.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "square.stack.3d.up.slash")
                        .font(.system(size: 40))
                        .foregroundColor(.dashboardTextSecondary)
                    Text("No modules yet")
                        .font(.headline)
                        .foregroundColor(.dashboardTextPrimary)
                    Text("Tap 'Add Module' above to get started")
                        .font(.subheadline)
                        .foregroundColor(.dashboardTextSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color.dashboardCard)
                .cornerRadius(16)
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.modules) { module in
                        NavigationLink(destination: ModuleLessonEditorView(module: module, courseId: viewModel.course.id ?? "")) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(module.title)
                                        .font(.headline)
                                        .foregroundColor(.dashboardTextPrimary)
                                    Text(module.moduleDescription)
                                        .font(.subheadline)
                                        .foregroundColor(.dashboardTextSecondary)
                                        .lineLimit(2)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.dashboardTextSecondary)
                            }
                            .padding()
                            .background(Color.dashboardCard)
                            .cornerRadius(16)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Action Card Component (Unused but kept for reference if needed elsewhere)

struct ActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.2))
                .cornerRadius(10)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.dashboardTextPrimary)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.dashboardTextSecondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.dashboardCard)
        .cornerRadius(12)
    }
}

struct AddModuleView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: CourseBuilderViewModel
    
    @State private var title = ""
    @State private var description = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        ZStack {
            Color.dashboardBg.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.dashboardTextSecondary)
                    Spacer()
                    Text("Add Module")
                        .font(.headline)
                        .foregroundColor(.dashboardTextPrimary)
                    Spacer()
                    Button("Add") {
                        Task {
                            isLoading = true
                            defer { isLoading = false }
                            do {
                                try await viewModel.createModule(title: title, description: description)
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                showError = true
                            }
                        }
                    }
                    .fontWeight(.bold)
                    .foregroundColor(.accentBlue)
                    .disabled(title.isEmpty || description.isEmpty || isLoading)
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 16) {
                            customTextField(title: "Module Title", text: $title)
                            customTextField(title: "Description", text: $description, isMultiline: true)
                        }
                        .padding()
                        .background(Color.dashboardCard)
                        .cornerRadius(20)
                    }
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "Failed to create module")
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
                    .scrollContentBackground(.hidden)
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
}

#Preview {
    CourseBuilderView(course: Course(
        id: "1",
        organizationId: "org1",
        title: "iOS Development",
        courseDescription: "Learn iOS development with SwiftUI",
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
