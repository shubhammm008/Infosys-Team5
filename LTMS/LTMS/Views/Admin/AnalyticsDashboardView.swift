//
//  AnalyticsDashboardView.swift
//  LTMS
//

import SwiftUI
import Combine
import Charts



@MainActor
class AnalyticsDashboardViewModel: ObservableObject {
    @Published var platformMetrics: PlatformMetrics?
    @Published var courseCompletionStats: [CourseCompletionStats] = []
    @Published var popularCourses: [PopularCourse] = []
    @Published var enrollmentTrends: [EnrollmentTrend] = []

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedDays = 30
    

    
    private let analyticsService = AnalyticsService()
    
    func loadAnalytics(organizationId: String) async {
        isLoading = true
        errorMessage = nil
        
        print("📊 [Analytics] Starting to load analytics for organization: \(organizationId)")
        
        do {
            async let metrics = analyticsService.fetchPlatformMetrics(organizationId: organizationId)
            async let completion = analyticsService.fetchAllCourseCompletionStats(organizationId: organizationId)
            async let popular = analyticsService.fetchPopularCourses(organizationId: organizationId)
            async let trends = analyticsService.fetchEnrollmentTrends(organizationId: organizationId, days: selectedDays)

            
            platformMetrics = try await metrics
            courseCompletionStats = try await completion
            popularCourses = try await popular
            enrollmentTrends = try await trends

            print("📊 [Analytics] Loaded \(popularCourses.count) popular courses")
            for course in popularCourses {
                print("   - \(course.courseTitle): \(course.enrollmentCount) enrollments")
            }
            print("📊 [Analytics] Loaded \(enrollmentTrends.count) enrollment trends")
            
        } catch {
            print("❌ [Analytics] Failed to load analytics: \(error)")
            errorMessage = "Failed to load analytics: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

struct AnalyticsDashboardView: View {
    @StateObject private var viewModel = AnalyticsDashboardViewModel()
    @EnvironmentObject var authService: SupabaseAuthService
    
    
    @State private var showCourseManagement = false
    @State private var showUserManagement = false
    @State private var selectedUserRole: UserRole? = nil
    @State private var selectedCourseId: String? = nil

    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.dashboardBg.ignoresSafeArea()
                
                if viewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.accentPrimary)
                        Text("Loading Analytics...")
                            .foregroundColor(.dashboardTextSecondary)
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.accentWarning)
                        Text(error)
                            .foregroundColor(.dashboardTextSecondary)
                        Button("Retry") {
                            Task {
                                await loadData()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.accentPrimary)
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Platform Usage Chart
                            platformUsageChart
                            
                            // Popular Courses (sorted by enrollment count)
                            if !viewModel.popularCourses.isEmpty {
                                popularCoursesSection
                            }
                            
                            // Course Completion Stats
                            if !viewModel.courseCompletionStats.isEmpty {
                                courseCompletionSection
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Analytics")
            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button {
//                        Task {
//                            await loadData()
//                        }
//                    } label: {
//                        Image(systemName: "arrow.clockwise")
//                    }
//                }
            }
            .task {
                await loadData()
                print("Enrollment trends:", viewModel.enrollmentTrends.count)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func loadData() async {
        if let organizationId = authService.currentUser?.organizationId {
            print("📊 [Analytics] Loading data for org: \(organizationId)")
            await viewModel.loadAnalytics(organizationId: organizationId)
        } else {
            print("⚠️ [Analytics] No organization ID found for current user!")
        }
    }
    
    @ViewBuilder
    private var platformUsageChart: some View {
        let trends = viewModel.enrollmentTrends
        
        // GUARANTEED drawable dataset
        let chartData: [EnrollmentTrend] = trends.isEmpty
            ? (0..<7).map {
                EnrollmentTrend(
                    date: Calendar.current.date(byAdding: .day, value: -$0, to: Date())!,
                    enrollmentCount: 0,
                    completionCount: 0
                )
            }.reversed()
            : trends.sorted { $0.date < $1.date }.suffix(30)
        
        VStack(alignment: .leading, spacing: 16) {
            Text("Enrollment Trends (Last 30 Days)")
                .font(.headline)
                .foregroundColor(.dashboardTextPrimary)
            
            Chart(chartData, id: \.date) {
                AreaMark(
                    x: .value("Date", $0.date),
                    y: .value("Enrollments", $0.enrollmentCount)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.accentBlue.opacity(0.6), Color.accentBlue.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                LineMark(
                    x: .value("Date", $0.date),
                    y: .value("Enrollments", $0.enrollmentCount)
                )
                .foregroundStyle(Color.accentBlue)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel {
                            Text(formatDate(date))
                                .font(.caption2)
                                .foregroundColor(Color.dashboardTextSecondary)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.gray.opacity(0.2))
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)")
                                .font(.caption2)
                                .foregroundColor(Color.dashboardTextSecondary)
                        }
                    }
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                        .foregroundStyle(Color.gray.opacity(0.2))
                }
            }
            .frame(height: 200)
            
            if trends.isEmpty {
                Text("No enrollment data yet. This chart will update automatically.")
                    .font(.caption)
                    .foregroundColor(.dashboardTextSecondary)
            }
        }
        .padding()
        .background(Color.dashboardCard)
        .cornerRadius(16)
    }



    
    
//    @ViewBuilder
//    private func platformOverviewSection(metrics: PlatformMetrics) -> some View {
//        VStack(alignment: .leading, spacing: 16) {
//            Text("Platform Overview")
//                .font(.title2)
//                .fontWeight(.bold)
//            
//            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
//                MetricCard(
//                    title: "Total Users",
//                    value: "\(metrics.totalUsers)",
//                    icon: "person.3.fill",
//                    color: .blue
//                )
//                
//                MetricCard(
//                    title: "Total Courses",
//                    value: "\(metrics.totalCourses)",
//                    icon: "book.fill",
//                    color: .purple
//                )
//                
//                MetricCard(
//                    title: "Enrollments",
//                    value: "\(metrics.totalEnrollments)",
//                    icon: "person.badge.plus",
//                    color: .orange
//                )
//                
//                MetricCard(
//                    title: "Avg Completion",
//                    value: String(format: "%.1f%%", metrics.averageCompletionRate),
//                    icon: "chart.line.uptrend.xyaxis",
//                    color: .teal
//                )
//            }
//        }
//        .padding()
//        .background(Color.dashboardCard)
//        .cornerRadius(16)
//    }
    
    
    
//    @ViewBuilder
//    private var enrollmentTrendsSection: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            HStack {
//                Text("Enrollment Trends")
//                    .font(.title2)
//                    .fontWeight(.bold)
//                
//                Spacer()
//                
//                Picker("Period", selection: $viewModel.selectedDays) {
//                    Text("7 days").tag(7)
//                    Text("30 days").tag(30)
//                    Text("90 days").tag(90)
//                }
//                .pickerStyle(.segmented)
//                .frame(width: 200)
//                .onChange(of: viewModel.selectedDays) {
//                    Task {
//                        await loadData()
//                    }
//                }
//            }
//            
//            if viewModel.enrollmentTrends.isEmpty {
//                Text("No enrollment data available")
//                    .foregroundColor(.dashboardTextSecondary)
//                    .padding()
//            } else {
//                // Simple trend visualization
//                VStack(alignment: .leading, spacing: 8) {
//                    ForEach(viewModel.enrollmentTrends.suffix(10), id: \.date) { trend in
//                        HStack {
//                            Text(formatDate(trend.date))
//                                .font(.caption)
//                                .foregroundColor(.dashboardTextSecondary)
//                                .frame(width: 80, alignment: .leading)
//                            
//                            HStack(spacing: 8) {
//                                Label("\(trend.enrollmentCount)", systemImage: "arrow.up.circle.fill")
//                                    .font(.caption)
//                                    .foregroundColor(.accentPrimary)
//                                
//                                Label("\(trend.completionCount)", systemImage: "checkmark.circle.fill")
//                                    .font(.caption)
//                                    .foregroundColor(.accentSuccess)
//                            }
//                            
//                            Spacer()
//                            
//                            // Simple bar visualization
//                            Rectangle()
//                                .fill(Color.accentPrimary.opacity(0.3))
//                                .frame(width: CGFloat(trend.enrollmentCount * 5), height: 20)
//                                .cornerRadius(4)
//                        }
//                    }
//                }
//            }
//        }
//        .padding()
//        .background(Color.dashboardCard)
//        .cornerRadius(16)
//    }
    
    @ViewBuilder
    private var popularCoursesSection: some View {
        // Sort courses by enrollment count (highest first)
        let sortedCourses = viewModel.popularCourses.sorted { $0.enrollmentCount > $1.enrollmentCount }
        
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Most Popular Courses")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button("View All") {
                    showCourseManagement = true
                }
                .font(.caption)
            }

            
            ForEach(sortedCourses.prefix(3), id: \.courseId) { course in
                Button {
                    selectedCourseId = course.courseId
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(course.courseTitle)
                                .font(.headline)
                                .foregroundColor(.dashboardTextPrimary)
                            Text("\(course.enrollmentCount) enrollments")
                                .font(.caption)
                                .foregroundColor(.dashboardTextSecondary)
                        }
                        
                        Spacer()
                        
                        // Show enrollment count badge
                        Text("\(course.enrollmentCount)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.accentPrimary)
                        
                        Image(systemName: "person.3.fill")
                            .foregroundColor(.accentPrimary)
                    }
                    .padding()
                    .background(Color.dashboardCardAlt)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color.dashboardCard)
        .cornerRadius(16)
        .sheet(isPresented: $showCourseManagement) {
            CourseManagementView()
        }
        .sheet(item: Binding(
            get: { selectedCourseId.flatMap { id in CourseIdentifier(id: id) } },
            set: { selectedCourseId = $0?.id }
        )) { courseIdentifier in
            if let course = viewModel.popularCourses.first(where: { $0.courseId == courseIdentifier.id }) {
                CourseDetailSheet(courseId: course.courseId, courseTitle: course.courseTitle)
            }
        }

    }
    
    @ViewBuilder
    private var courseCompletionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Course Completion Rates")
                    .font(.title2)
                    .fontWeight(.bold)

            }
            
            ForEach(viewModel.courseCompletionStats.sorted { $0.completionRate > $1.completionRate }.prefix(3), id: \.courseId) { stat in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(stat.courseTitle)
                            .font(.headline)
                        Spacer()
                        Text(String(format: "%.1f%%", stat.completionRate))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(completionColor(stat.completionRate))
                    }
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                                .cornerRadius(4)
                            
                            Rectangle()
                                .fill(completionColor(stat.completionRate))
                                .frame(width: geometry.size.width * CGFloat(stat.completionRate / 100), height: 8)
                                .cornerRadius(4)
                        }
                    }
                    .frame(height: 8)
                    
                    HStack(spacing: 16) {
                        Label("\(stat.completedEnrollments) completed", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.accentSuccess)
                        
                        Label("\(stat.activeEnrollments) active", systemImage: "circle.fill")
                            .font(.caption)
                            .foregroundColor(.accentPrimary)
                        
                        if stat.droppedEnrollments > 0 {
                            Label("\(stat.droppedEnrollments) dropped", systemImage: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        if let avgTime = stat.averageTimeToComplete {
                            Label(String(format: "%.1f days avg", avgTime), systemImage: "clock.fill")
                                .font(.caption)
                                .foregroundColor(.accentWarning)
                        }
                    }
                }
                .padding()
                .background(Color.dashboardCardAlt)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.dashboardCard)
        .cornerRadius(16)
    }
    

    
    private func completionColor(_ rate: Double) -> Color {
        if rate >= 70 {
            return .accentSuccess
        } else if rate >= 40 {
            return .accentWarning
        } else {
            return .accentSecondary
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.dashboardTextSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// Helper struct for sheet presentation
struct CourseIdentifier: Identifiable {
    let id: String
}

// Course Detail Sheet
struct CourseDetailSheet: View {
    let courseId: String
    let courseTitle: String
    @Environment(\.dismiss) private var dismiss
    @State private var course: Course?
    @State private var isLoading = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.dashboardBg.ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .tint(.accentPrimary)
                } else if let course = course {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Course Header
                            VStack(alignment: .leading, spacing: 12) {
                                Text(course.title)
                                    .font(.title)
                                    .fontWeight(.bold)
                                
                                Text(course.courseDescription)
                                    .font(.body)
                                    .foregroundColor(.dashboardTextSecondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.dashboardCard)
                            .cornerRadius(16)
                            
                            // Course Details
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Course Details")
                                    .font(.headline)
                                
                                DetailRow(icon: "clock", label: "Duration", value: "\(course.durationHours) hours")
                                DetailRow(icon: "chart.bar", label: "Level", value: course.level.displayName)
                                DetailRow(icon: "checkmark.circle", label: "Status", value: course.isPublished ? "Published" : "Draft")
                                
                                if let maxEnrollments = course.maxEnrollments {
                                    DetailRow(icon: "person.2", label: "Max Enrollments", value: "\(maxEnrollments)")
                                }
                            }
                            .padding()
                            .background(Color.dashboardCard)
                            .cornerRadius(16)
                        }
                        .padding()
                    }
                } else {
                    Text("Course not found")
                        .foregroundColor(.dashboardTextSecondary)
                }
            }
            .navigationTitle("Course Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadCourse()
            }
        }
    }
    
    private func loadCourse() async {
        do {
            course = try await CourseService.shared.fetchCourse(id: courseId)
        } catch {
            print("❌ Error loading course: \(error)")
        }
        isLoading = false
    }
}

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentPrimary)
                .frame(width: 24)
            
            Text(label)
                .foregroundColor(.dashboardTextSecondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    AnalyticsDashboardView()
        .environmentObject(SupabaseAuthService.shared)
}
