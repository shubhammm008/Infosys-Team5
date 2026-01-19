//
//  EducatorAnalyticsView.swift
//  LTMS
//
//  Created for Educator Analytics Feature
//

import SwiftUI
import Charts
import Combine

// MARK: - Main Analytics View
struct EducatorAnalyticsView: View {
    @StateObject private var viewModel = EducatorAnalyticsViewModel()
    @StateObject private var authService = SupabaseAuthService.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.dashboardBg.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 28) {
                        header
                        
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.accentBlue)
                                .padding(.top, 60)
                        } else if viewModel.courses.isEmpty {
                            emptyState
                        } else {
                            overviewStatsSection
                            enrollmentTrendChart
                            coursePerformanceSection
                        }
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
            .task {
                if let userId = authService.currentUser?.id {
                    await viewModel.loadAnalytics(educatorId: userId)
                }
            }
        }
    }
    
    // MARK: - Header
    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Analytics")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.dashboardTextPrimary)
                
                Text("Course Performance Overview")
                    .font(.subheadline)
                    .foregroundColor(.dashboardTextSecondary)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 60))
                .foregroundColor(.dashboardTextSecondary)
            
            Text("No Analytics Available")
                .font(.headline)
                .foregroundColor(.dashboardTextPrimary)
            
            Text("Create or get assigned to courses to see analytics.")
                .font(.subheadline)
                .foregroundColor(.dashboardTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Overview Stats
    private var overviewStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
                .font(.headline)
                .foregroundColor(.dashboardTextPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                statCard(
                    title: "Total Courses",
                    value: "\(viewModel.totalCourses)",
                    icon: "book.fill",
                    color: .accentBlue
                )
                
                statCard(
                    title: "Total Enrollments",
                    value: "\(viewModel.totalEnrollments)",
                    icon: "person.3.fill",
                    color: .green
                )
                
                statCard(
                    title: "Avg Completion",
                    value: "\(Int(viewModel.averageCompletionRate))%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .orange
                )
                
                statCard(
                    title: "Active Learners",
                    value: "\(viewModel.activeLearners)",
                    icon: "person.fill.checkmark",
                    color: .purple
                )
            }
        }
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.dashboardTextPrimary)
            
            Text(title.uppercased())
                .font(.caption)
                .foregroundColor(.dashboardTextSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 110)
        .background(Color.dashboardCard)
        .cornerRadius(16)
    }
    
    // MARK: - Enrollment Trend Chart
    private var enrollmentTrendChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Enrollment Trends (Last 30 Days)")
                .font(.headline)
                .foregroundColor(.dashboardTextPrimary)
            
            if viewModel.enrollmentTrends.isEmpty {
                Text("No enrollment data available")
                    .font(.subheadline)
                    .foregroundColor(.dashboardTextSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                Chart {
                    ForEach(viewModel.enrollmentTrends, id: \.date) { trend in
                        LineMark(
                            x: .value("Date", trend.date, unit: .day),
                            y: .value("Enrollments", trend.enrollmentCount)
                        )
                        .foregroundStyle(Color.accentBlue)
                        .interpolationMethod(.catmullRom)
                        
                        AreaMark(
                            x: .value("Date", trend.date, unit: .day),
                            y: .value("Enrollments", trend.enrollmentCount)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.accentBlue.opacity(0.3), Color.accentBlue.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month().day())
                            .foregroundStyle(Color.dashboardTextSecondary)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel()
                            .foregroundStyle(Color.dashboardTextSecondary)
                    }
                }
            }
        }
        .padding()
        .background(Color.dashboardCard)
        .cornerRadius(16)
    }
    
    // MARK: - Course Performance
    private var coursePerformanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Course Performance")
                .font(.headline)
                .foregroundColor(.dashboardTextPrimary)
            
            ForEach(viewModel.courseStats) { stats in
                CoursePerformanceCard(stats: stats)
            }
        }
    }
}

// MARK: - Course Performance Card
struct CoursePerformanceCard: View {
    let stats: CourseCompletionStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Course Title
            Text(stats.courseTitle)
                .font(.headline)
                .foregroundColor(.dashboardTextPrimary)
            
            // Enrollment Stats
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ENROLLMENTS")
                        .font(.caption2)
                        .foregroundColor(.dashboardTextSecondary)
                    Text("\(stats.totalEnrollments)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.dashboardTextPrimary)
                }
                
                Divider()
                    .frame(height: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("ACTIVE")
                        .font(.caption2)
                        .foregroundColor(.dashboardTextSecondary)
                    Text("\(stats.activeEnrollments)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.accentBlue)
                }
                
                Divider()
                    .frame(height: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("COMPLETED")
                        .font(.caption2)
                        .foregroundColor(.dashboardTextSecondary)
                    Text("\(stats.completedEnrollments)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                Spacer()
            }
            
            // Completion Rate Bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Completion Rate")
                        .font(.caption)
                        .foregroundColor(.dashboardTextSecondary)
                    Spacer()
                    Text("\(Int(stats.completionRate))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.dashboardTextPrimary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.dashboardTextSecondary.opacity(0.2))
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [.accentBlue, .accentBlue.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(stats.completionRate / 100), height: 8)
                    }
                }
                .frame(height: 8)
            }
            
            // Average Progress
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.caption)
                    .foregroundColor(.dashboardTextSecondary)
                Text("Avg. Progress: \(Int(stats.averageCompletionPercentage))%")
                    .font(.caption)
                    .foregroundColor(.dashboardTextSecondary)
            }
        }
        .padding()
        .background(Color.dashboardCard)
        .cornerRadius(16)
    }
}

// MARK: - View Model
@MainActor
class EducatorAnalyticsViewModel: ObservableObject {
    @Published var courses: [Course] = []
    @Published var courseStats: [CourseCompletionStats] = []
    @Published var enrollmentTrends: [EnrollmentTrend] = []
    @Published var isLoading = false
    
    private let analyticsService = AnalyticsService()
    private let courseService = CourseService.shared
    
    var totalCourses: Int {
        courses.count
    }
    
    var totalEnrollments: Int {
        courseStats.reduce(0) { $0 + $1.totalEnrollments }
    }
    
    var averageCompletionRate: Double {
        guard !courseStats.isEmpty else { return 0 }
        let sum = courseStats.reduce(0.0) { $0 + $1.completionRate }
        return sum / Double(courseStats.count)
    }
    
    var activeLearners: Int {
        courseStats.reduce(0) { $0 + $1.activeEnrollments }
    }
    
    var recentEnrollmentsCount: Int {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return enrollmentTrends
            .filter { $0.date >= sevenDaysAgo }
            .reduce(0) { $0 + $1.enrollmentCount }
    }
    
    var averageCompletionTime: Double? {
        let times = courseStats.compactMap { $0.averageTimeToComplete }
        guard !times.isEmpty else { return nil }
        return times.reduce(0, +) / Double(times.count)
    }
    
    func loadAnalytics(educatorId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Fetch educator's courses
            let allCourses: [Course] = try await SupabaseService.shared.fetchAll(from: SupabaseConstants.courses)
            courses = allCourses.filter { $0.assignedEducatorId == educatorId || $0.createdById == educatorId }
            
            print("📊 [Educator Analytics] Found \(courses.count) courses for educator")
            
            // Fetch stats for each course
            var stats: [CourseCompletionStats] = []
            for course in courses {
                if let courseId = course.id {
                    let courseStat = try await analyticsService.fetchCourseCompletionStats(courseId: courseId)
                    stats.append(courseStat)
                }
            }
            courseStats = stats.sorted { $0.totalEnrollments > $1.totalEnrollments }
            
            // Fetch enrollment trends for educator's courses
            await loadEnrollmentTrends(educatorId: educatorId)
            
            print("📊 [Educator Analytics] Loaded analytics: \(totalEnrollments) total enrollments, \(Int(averageCompletionRate))% avg completion")
            
        } catch {
            print("❌ Error loading educator analytics: \(error)")
            courses = []
            courseStats = []
            enrollmentTrends = []
        }
    }
    
    private func loadEnrollmentTrends(educatorId: String) async {
        do {
            // Get all enrollments for educator's courses
            var allTrends: [Date: Int] = [:]
            
            for course in courses {
                guard let courseId = course.id else { continue }
                
                let enrollments: [Enrollment] = try await SupabaseService.shared.query(
                    from: SupabaseConstants.enrollments,
                    where: "course_id",
                    equals: courseId
                )
                
                // Group by date
                for enrollment in enrollments {
                    let calendar = Calendar.current
                    let enrollmentDay = calendar.startOfDay(for: enrollment.enrollmentDate)
                    
                    // Only include last 30 days
                    let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
                    if enrollmentDay >= thirtyDaysAgo {
                        allTrends[enrollmentDay, default: 0] += 1
                    }
                }
            }
            
            // Convert to EnrollmentTrend array
            enrollmentTrends = allTrends.map { date, count in
                EnrollmentTrend(date: date, enrollmentCount: count, completionCount: 0)
            }.sorted { $0.date < $1.date }
            
            print("📊 [Educator Analytics] Generated \(enrollmentTrends.count) trend data points")
            
        } catch {
            print("❌ Error loading enrollment trends: \(error)")
            enrollmentTrends = []
        }
    }
}

// MARK: - Identifiable Extension
extension CourseCompletionStats: Identifiable {
    var id: String { courseId }
}

#Preview {
    EducatorAnalyticsView()
}
