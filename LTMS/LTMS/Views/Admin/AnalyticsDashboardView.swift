//
//  AnalyticsDashboardView.swift
//  LTMS
//
//  Created by AI Assistant on 13/01/26.
//

import SwiftUI
import Combine

@MainActor
class AnalyticsDashboardViewModel: ObservableObject {
    @Published var platformMetrics: PlatformMetrics?
    @Published var courseCompletionStats: [CourseCompletionStats] = []
    @Published var popularCourses: [PopularCourse] = []
    @Published var enrollmentTrends: [EnrollmentTrend] = []
    @Published var userActivityMetrics: [UserActivityMetrics] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedDays = 30
    
    private let analyticsService = AnalyticsService()
    
    func loadAnalytics(organizationId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let metrics = analyticsService.fetchPlatformMetrics(organizationId: organizationId)
            async let completion = analyticsService.fetchAllCourseCompletionStats(organizationId: organizationId)
            async let popular = analyticsService.fetchPopularCourses(organizationId: organizationId)
            async let trends = analyticsService.fetchEnrollmentTrends(organizationId: organizationId, days: selectedDays)
            async let activity = analyticsService.fetchUserActivityMetrics(organizationId: organizationId, role: .learner)
            
            platformMetrics = try await metrics
            courseCompletionStats = try await completion
            popularCourses = try await popular
            enrollmentTrends = try await trends
            userActivityMetrics = try await activity
            
        } catch {
            errorMessage = "Failed to load analytics: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

struct AnalyticsDashboardView: View {
    @StateObject private var viewModel = AnalyticsDashboardViewModel()
    @EnvironmentObject var authService: SupabaseAuthService
    
    var body: some View {
        NavigationView {
            ScrollView {
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text(error)
                            .foregroundColor(.secondary)
                        Button("Retry") {
                            Task {
                                await loadData()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    VStack(spacing: 24) {
                        // Platform Overview
                        if let metrics = viewModel.platformMetrics {
                            platformOverviewSection(metrics: metrics)
                        }
                        
                        // Enrollment Trends
                        if !viewModel.enrollmentTrends.isEmpty {
                            enrollmentTrendsSection
                        }
                        
                        // Popular Courses
                        if !viewModel.popularCourses.isEmpty {
                            popularCoursesSection
                        }
                        
                        // Course Completion Stats
                        if !viewModel.courseCompletionStats.isEmpty {
                            courseCompletionSection
                        }
                        
                        // Top Active Users
                        if !viewModel.userActivityMetrics.isEmpty {
                            topUsersSection
                        }
                    }
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Analytics Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await loadData()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task {
                await loadData()
            }
        }
    }
    
    private func loadData() async {
        if let organizationId = authService.currentUser?.organizationId {
            await viewModel.loadAnalytics(organizationId: organizationId)
        }
    }
    
    @ViewBuilder
    private func platformOverviewSection(metrics: PlatformMetrics) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Platform Overview")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                MetricCard(
                    title: "Total Users",
                    value: "\(metrics.totalUsers)",
                    icon: "person.3.fill",
                    color: .blue
                )
                
                MetricCard(
                    title: "Active (7 days)",
                    value: "\(metrics.activeUsersLast7Days)",
                    icon: "person.wave.2.fill",
                    color: .green
                )
                
                MetricCard(
                    title: "Total Courses",
                    value: "\(metrics.totalCourses)",
                    icon: "book.fill",
                    color: .purple
                )
                
                MetricCard(
                    title: "Enrollments",
                    value: "\(metrics.totalEnrollments)",
                    icon: "person.badge.plus",
                    color: .orange
                )
                
                MetricCard(
                    title: "Learning Hours",
                    value: String(format: "%.1f", metrics.totalLearningTimeHours),
                    icon: "clock.fill",
                    color: .red
                )
                
                MetricCard(
                    title: "Avg Completion",
                    value: String(format: "%.1f%%", metrics.averageCompletionRate),
                    icon: "chart.line.uptrend.xyaxis",
                    color: .teal
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    @ViewBuilder
    private var enrollmentTrendsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Enrollment Trends")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Picker("Period", selection: $viewModel.selectedDays) {
                    Text("7 days").tag(7)
                    Text("30 days").tag(30)
                    Text("90 days").tag(90)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                .onChange(of: viewModel.selectedDays) {
                    Task {
                        await loadData()
                    }
                }
            }
            
            if viewModel.enrollmentTrends.isEmpty {
                Text("No enrollment data available")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                // Simple trend visualization
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.enrollmentTrends.suffix(10), id: \.date) { trend in
                        HStack {
                            Text(formatDate(trend.date))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 80, alignment: .leading)
                            
                            HStack(spacing: 8) {
                                Label("\(trend.enrollmentCount)", systemImage: "arrow.up.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                
                                Label("\(trend.completionCount)", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            
                            Spacer()
                            
                            // Simple bar visualization
                            Rectangle()
                                .fill(Color.blue.opacity(0.3))
                                .frame(width: CGFloat(trend.enrollmentCount * 5), height: 20)
                                .cornerRadius(4)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    @ViewBuilder
    private var popularCoursesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Most Popular Courses")
                .font(.title2)
                .fontWeight(.bold)
            
            ForEach(viewModel.popularCourses.prefix(5), id: \.courseId) { course in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(course.courseTitle)
                            .font(.headline)
                        Text("\(course.enrollmentCount) enrollments")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "person.3.fill")
                        .foregroundColor(.blue)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    @ViewBuilder
    private var courseCompletionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Course Completion Rates")
                .font(.title2)
                .fontWeight(.bold)
            
            ForEach(viewModel.courseCompletionStats.sorted { $0.completionRate > $1.completionRate }.prefix(10), id: \.courseId) { stat in
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
                            .foregroundColor(.green)
                        
                        Label("\(stat.activeEnrollments) active", systemImage: "circle.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        if stat.droppedEnrollments > 0 {
                            Label("\(stat.droppedEnrollments) dropped", systemImage: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        if let avgTime = stat.averageTimeToComplete {
                            Label(String(format: "%.1f days avg", avgTime), systemImage: "clock.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    @ViewBuilder
    private var topUsersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Most Active Learners")
                .font(.title2)
                .fontWeight(.bold)
            
            ForEach(viewModel.userActivityMetrics.prefix(10), id: \.userId) { metric in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(metric.userName)
                            .font(.headline)
                        HStack(spacing: 12) {
                            Label("\(metric.loginCount) logins", systemImage: "rectangle.portrait.and.arrow.right")
                                .font(.caption)
                            Label("\(metric.totalEnrollments) courses", systemImage: "book.fill")
                                .font(.caption)
                            Label(String(format: "%.1fh", metric.totalLearningTimeHours), systemImage: "clock.fill")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(metric.completedCourses)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("completed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    private func completionColor(_ rate: Double) -> Color {
        if rate >= 70 {
            return .green
        } else if rate >= 40 {
            return .orange
        } else {
            return .red
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
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    AnalyticsDashboardView()
        .environmentObject(SupabaseAuthService.shared)
}
