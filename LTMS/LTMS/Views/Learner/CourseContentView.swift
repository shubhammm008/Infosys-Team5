

import SwiftUI
import Combine

@MainActor
class CourseContentViewModel: ObservableObject {
    @Published var modules: [Module] = []
    @Published var lessonsByModule: [String: [Lesson]] = [:]
    @Published var enrollment: Enrollment?
    @Published var progressMap: [String: Progress] = [:] // lessonId -> Progress
    @Published var isLoading = false
    @Published var expandedModules: Set<String> = []
    
    let course: Course
    let learnerId: String
    
    init(course: Course, learnerId: String) {
        self.course = course
        self.learnerId = learnerId
    }
    
    func loadCourseContent() async {
        guard let courseId = course.id else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Load enrollment
            let enrollments = try await ContentService.shared.fetchEnrollmentsByLearner(learnerId: learnerId)
            enrollment = enrollments.first { $0.courseId == courseId }
            
            // Update last accessed time if enrolled
            if var enrollmentToUpdate = enrollment {
                enrollmentToUpdate.lastAccessed = Date()
                try await ContentService.shared.updateEnrollment(enrollmentToUpdate)
                enrollment = enrollmentToUpdate
            }
            
            // Load modules
            modules = try await CourseService.shared.fetchModulesByCourse(courseId: courseId)
            
            // Load lessons for each module
            for module in modules {
                if let moduleId = module.id {
                    let lessons = try await CourseService.shared.fetchLessonsByModule(moduleId: moduleId)
                    lessonsByModule[moduleId] = lessons
                }
            }
            
            // Load progress if enrolled
            if let enrollmentId = enrollment?.id {
                let allProgress = try await ContentService.shared.fetchProgressByEnrollment(enrollmentId: enrollmentId)
                progressMap = Dictionary(uniqueKeysWithValues: allProgress.compactMap { progress in
                    (progress.lessonId, progress)
                })
            }
            
            // Expand first module by default
            if let firstModule = modules.first, let id = firstModule.id {
                expandedModules.insert(id)
            }
            
        } catch {
            print("❌ Error loading course content: \(error)")
        }
    }
    
    func toggleModule(_ moduleId: String) {
        if expandedModules.contains(moduleId) {
            expandedModules.remove(moduleId)
        } else {
            expandedModules.insert(moduleId)
        }
    }
    
    func isLessonCompleted(_ lessonId: String) -> Bool {
        progressMap[lessonId]?.isCompleted ?? false
    }
    
    func completionPercentage(for module: Module) -> Double {
        guard let moduleId = module.id,
              let lessons = lessonsByModule[moduleId],
              !lessons.isEmpty else {
            return 0
        }
        
        let completedCount = lessons.filter { lesson in
            isLessonCompleted(lesson.id ?? "")
        }.count
        
        return Double(completedCount) / Double(lessons.count)
    }
}

struct CourseContentView: View {
    @StateObject private var viewModel: CourseContentViewModel
    @StateObject private var authService = SupabaseAuthService.shared
    
    init(course: Course) {
        let userId = SupabaseAuthService.shared.currentUser?.id ?? ""
        _viewModel = StateObject(wrappedValue: CourseContentViewModel(course: course, learnerId: userId))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Course Header
                courseHeader
                
                // Course Overview
                if !viewModel.isLoading {
                    courseOverview
                }
                
                // Quizzes Section
                if !viewModel.isLoading {
                    quizzesSection
                }
                
                // Course Content (Modules & Lessons)
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                } else if viewModel.modules.isEmpty {
                    emptyState
                } else {
                    courseSyllabus
                }
            }
            .padding()
        }
        .background(Color.ltmsBackground)
        .navigationTitle(viewModel.course.title)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadCourseContent()
        }
    }
    
    // MARK: - Course Header
    
    private var courseHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Thumbnail
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [.ltmsPrimary, .ltmsSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 180)
                .overlay(
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.9))
                )
            
            // Course Info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("\(viewModel.course.durationHours)h", systemImage: "clock")
                    Divider().frame(height: 12)
                    Label(viewModel.course.level.displayName, systemImage: "chart.bar")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                if let enrollment = viewModel.enrollment {
                    ProgressBar(value: enrollment.completionPercentage / 100.0)
                    Text("\(Int(enrollment.completionPercentage))% Complete")
                        .font(.caption)
                        .foregroundColor(.ltmsPrimary)
                        .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Course Overview
    
    private var courseOverview: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About this course")
                .font(.title3)
                .fontWeight(.bold)
            
            Text(viewModel.course.courseDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Stats
            HStack(spacing: 20) {
                StatBadge(
                    icon: "square.stack.3d.up",
                    title: "\(viewModel.modules.count) Modules",
                    color: .purple
                )
                
                StatBadge(
                    icon: "play.circle",
                    title: "\(totalLessons) Lessons",
                    color: .blue
                )
            }
        }
        .padding()
        .background(Color.ltmsCardBackground)
        .cornerRadius(16)
    }
    
    private var totalLessons: Int {
        viewModel.lessonsByModule.values.reduce(0) { $0 + $1.count }
    }
    
    // MARK: - Quizzes Section
    
    private var quizzesSection: some View {
        NavigationLink(destination: CourseQuizzesView(course: viewModel.course)) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "questionmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Course Quizzes")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Test your knowledge")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.ltmsCardBackground)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Course Syllabus
    
    private var courseSyllabus: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Course Syllabus")
                .font(.title3)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                ForEach(Array(viewModel.modules.enumerated()), id: \.element.id) { index, module in
                    ModuleAccordion(
                        module: module,
                        moduleNumber: index + 1,
                        isExpanded: viewModel.expandedModules.contains(module.id ?? ""),
                        lessons: viewModel.lessonsByModule[module.id ?? ""] ?? [],
                        completionPercentage: viewModel.completionPercentage(for: module),
                        viewModel: viewModel,
                        onToggle: {
                            viewModel.toggleModule(module.id ?? "")
                        }
                    )
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("Course content coming soon")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("The instructor is preparing the materials")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Module Accordion

struct ModuleAccordion: View {
    let module: Module
    let moduleNumber: Int
    let isExpanded: Bool
    let lessons: [Lesson]
    let completionPercentage: Double
    @ObservedObject var viewModel: CourseContentViewModel
    let onToggle: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Module Header
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    // Module number badge
                    ZStack {
                        Circle()
                            .fill(Color.ltmsPrimary.opacity(0.2))
                            .frame(width: 40, height: 40)
                        Text("\(moduleNumber)")
                            .font(.headline)
                            .foregroundColor(.ltmsPrimary)
                    }
                    
                    // Module info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(module.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        HStack(spacing: 8) {
                            Text("\(lessons.count) lessons")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if completionPercentage > 0 {
                                Text("• \(Int(completionPercentage * 100))% complete")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.ltmsCardBackground)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            // Lessons List (Expanded)
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(Array(lessons.enumerated()), id: \.element.id) { index, lesson in
                        NavigationLink(destination: LessonViewerView(
                            lesson: lesson,
                            courseId: viewModel.course.id ?? "",
                            enrollmentId: viewModel.enrollment?.id
                        )) {
                            LessonRow(
                                lesson: lesson,
                                lessonNumber: index + 1,
                                isCompleted: viewModel.isLessonCompleted(lesson.id ?? "")
                            )
                        }
                        .buttonStyle(.plain)
                        
                        if index < lessons.count - 1 {
                            Divider()
                                .padding(.leading, 60)
                        }
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal)
                .padding(.bottom)
                .background(Color.ltmsCardBackground.opacity(0.5))
                .cornerRadius(12)
                .padding(.top, 4)
            }
        }
    }
}

// MARK: - Lesson Row

struct LessonRow: View {
    let lesson: Lesson
    let lessonNumber: Int
    let isCompleted: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Completion indicator
            ZStack {
                Circle()
                    .stroke(isCompleted ? Color.green : Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: 24, height: 24)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundColor(.green)
                }
            }
            
            // Lesson info
            VStack(alignment: .leading, spacing: 4) {
                Text("Lesson \(lessonNumber): \(lesson.title)")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                if let objectives = lesson.learningObjectives, !objectives.isEmpty {
                    Text(objectives)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Supporting Views

struct ProgressBar: View {
    let value: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [.ltmsPrimary, .ltmsSecondary],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * value)
            }
        }
        .frame(height: 8)
    }
}

struct StatBadge: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    NavigationStack {
        CourseContentView(course: Course(
            id: "1",
            organizationId: AppConstants.defaultOrganizationId,
            title: "Complete SwiftUI Masterclass",
            courseDescription: "Learn SwiftUI from scratch",
            level: .intermediate,
            durationHours: 40,
            thumbnailURL: nil,
            isPublished: true,
            createdById: "user1",
            assignedEducatorId: "educator1",
            prerequisites: ["Basic Swift knowledge"],
            learningObjectives: ["Build iOS apps", "Master SwiftUI"],
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
