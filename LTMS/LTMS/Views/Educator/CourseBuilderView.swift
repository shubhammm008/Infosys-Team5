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

struct CourseBuilderView: View {
    @StateObject private var viewModel: CourseBuilderViewModel
    @State private var showAddModule = false
    @State private var showCourseDetails = false
    
    init(course: Course) {
        _viewModel = StateObject(wrappedValue: CourseBuilderViewModel(course: course))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Course Info Card
                courseInfoCard
                
                // Action Cards Section
                actionCardsSection
                
                // Modules Section
                modulesSection
            }
            .padding()
        }
        .background(Color.ltmsBackground)
        .navigationTitle("Course Builder")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showCourseDetails = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.title3)
                }
            }
        }
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
    
    // MARK: - Course Info Card
    
    private var courseInfoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.course.title)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(viewModel.course.courseDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Label("\(viewModel.course.durationHours)h", systemImage: "clock")
                Text(viewModel.course.level.displayName)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.ltmsPrimary.opacity(0.2))
                    .foregroundColor(.ltmsPrimary)
                    .cornerRadius(6)
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.ltmsCardBackground)
        .cornerRadius(16)
    }
    
    // MARK: - Action Cards Section
    
    private var actionCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.secondary)
            
            // Add Module Card (full width since Quizzes is now per-lesson)
            Button {
                showAddModule = true
            } label: {
                HStack {
                    Image(systemName: "plus.rectangle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .frame(width: 44, height: 44)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(10)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Add Module")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Text("Create new module with lessons")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .padding()
                .background(Color.ltmsCardBackground)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            // Info Note
//            HStack(spacing: 8) {
//                Image(systemName: "info.circle")
//                    .foregroundColor(.purple)
//                Text("Quizzes are now created within each lesson")
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Modules Section
    
    private var modulesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Modules")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(viewModel.modules.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.ltmsPrimary.opacity(0.2))
                    .foregroundColor(.ltmsPrimary)
                    .cornerRadius(6)
            }
            
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, 40)
            } else if viewModel.modules.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "square.stack.3d.up.slash")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No modules yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Tap 'Add Module' above to get started")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color.ltmsCardBackground)
                .cornerRadius(16)
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.modules) { module in
                        NavigationLink(destination: ModuleLessonEditorView(module: module, courseId: viewModel.course.id ?? "")) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(module.title)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text(module.moduleDescription)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.ltmsCardBackground)
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Action Card Component

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
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.ltmsCardBackground)
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
        NavigationStack {
            Form {
                Section("Module Information") {
                    TextField("Module Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Button("Add Module") {
                        Task {
                            isLoading = true
                            defer { isLoading = false }
                            do {
                                try await viewModel.createModule(title: title, description: description)
                                dismiss()
                            } catch {
                                errorMessage = error.localizedDescription
                                showError = true
                                print("❌ Failed to add module: \(error)")
                            }
                        }
                    }
                    .disabled(title.isEmpty || description.isEmpty || isLoading)
                }
            }
            .navigationTitle("Add Module")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "Failed to create module")
            }
        }
    }
}

#Preview {
    NavigationStack {
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
}
