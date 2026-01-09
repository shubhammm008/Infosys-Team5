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
    
    let course: Course
    
    init(course: Course) {
        self.course = course
    }
    
    func loadModules() async {
        let courseId = course.id
        isLoading = true
        defer { isLoading = false }
        
        do {
            modules = try await CourseService.shared.fetchModulesByCourse(courseId: courseId)
        } catch {
            print("Error loading modules: \(error)")
        }
    }
    
    func createModule(title: String, description: String) async throws {
        let courseId = course.id
        
        let module = Module(
            id: UUID().uuidString,
            courseId: courseId,
            title: title,
            moduleDescription: description,
            orderIndex: modules.count,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        _ = try await CourseService.shared.createModule(module)
        await loadModules()
    }
}

struct CourseBuilderView: View {
    @StateObject private var viewModel: CourseBuilderViewModel
    @State private var showAddModule = false
    
    init(course: Course) {
        _viewModel = StateObject(wrappedValue: CourseBuilderViewModel(course: course))
    }
    
    var body: some View {
        List {
            Section {
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
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
            
            Section {
                if viewModel.modules.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "square.stack.3d.up.slash")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No modules yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Button("Add First Module") {
                            showAddModule = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(viewModel.modules) { module in
                        NavigationLink(destination: ModuleLessonEditorView(module: module)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(module.title)
                                    .font(.headline)
                                Text(module.moduleDescription)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Modules")
                    Spacer()
                    Button {
                        showAddModule = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
        }
        .navigationTitle("Course Builder")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddModule) {
            AddModuleView(viewModel: viewModel)
        }
        .task {
            await viewModel.loadModules()
        }
    }
}

struct AddModuleView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: CourseBuilderViewModel
    
    @State private var title = ""
    @State private var description = ""
    @State private var isLoading = false
    
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
                            try? await viewModel.createModule(title: title, description: description)
                            dismiss()
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
            updatedAt: Date()
        ))
    }
}
