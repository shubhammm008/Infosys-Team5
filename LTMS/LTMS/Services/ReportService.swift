//
//  ReportService.swift
//  LTMS
//
//  Created by Shubham Singh on 13/01/26.
//

import Foundation
import UniformTypeIdentifiers

enum ReportType: String, CaseIterable {
    case platformUsage = "Platform Usage Report"
    case courseCompletion = "Course Completion Report"
    case enrollmentSummary = "Enrollment Summary Report"
    case learnerProgress = "Learner Progress Report"
    case userActivity = "User Activity Report"
    
    var description: String {
        switch self {
        case .platformUsage:
            return "Overview of platform metrics, active users, and engagement"
        case .courseCompletion:
            return "Completion rates and statistics for all courses"
        case .enrollmentSummary:
            return "Summary of enrollments across courses"
        case .learnerProgress:
            return "Detailed progress report for all learners"
        case .userActivity:
            return "User login activity and engagement metrics"
        }
    }
    
    var icon: String {
        switch self {
        case .platformUsage: return "chart.bar.fill"
        case .courseCompletion: return "checkmark.circle.fill"
        case .enrollmentSummary: return "person.badge.plus"
        case .learnerProgress: return "chart.line.uptrend.xyaxis"
        case .userActivity: return "person.wave.2.fill"
        }
    }
}

class ReportService {
    private let analyticsService = AnalyticsService()
    private let supabaseService = SupabaseService.shared
    
    // MARK: - CSV Generation
    
    func generatePlatformUsageReport(organizationId: String) async throws -> String {
        let metrics = try await analyticsService.fetchPlatformMetrics(organizationId: organizationId)
        
        var csv = "Platform Usage Report\n"
        csv += "Generated: \(formatDateTime(Date()))\n\n"
        
        csv += "Metric,Value\n"
        csv += "Total Users,\(metrics.totalUsers)\n"
        csv += "Active Users (7 days),\(metrics.activeUsersLast7Days)\n"
        csv += "Active Users (30 days),\(metrics.activeUsersLast30Days)\n"
        csv += "Total Courses,\(metrics.totalCourses)\n"
        csv += "Total Enrollments,\(metrics.totalEnrollments)\n"
        csv += "Total Learning Hours,\(String(format: "%.2f", metrics.totalLearningTimeHours))\n"
        csv += "Average Completion Rate,\(String(format: "%.2f%%", metrics.averageCompletionRate))\n"
        
        return csv
    }
    
    func generateCourseCompletionReport(organizationId: String) async throws -> String {
        let stats = try await analyticsService.fetchAllCourseCompletionStats(organizationId: organizationId)
        
        var csv = "Course Completion Report\n"
        csv += "Generated: \(formatDateTime(Date()))\n\n"
        
        csv += "Course Title,Total Enrollments,Completed,Active,Dropped,Completion Rate (%),Average Completion (%),Average Time to Complete (days)\n"
        
        for stat in stats.sorted(by: { $0.completionRate > $1.completionRate }) {
            let avgTime = stat.averageTimeToComplete.map { String(format: "%.1f", $0) } ?? "N/A"
            csv += "\"\(stat.courseTitle)\","
            csv += "\(stat.totalEnrollments),"
            csv += "\(stat.completedEnrollments),"
            csv += "\(stat.activeEnrollments),"
            csv += "\(stat.droppedEnrollments),"
            csv += "\(String(format: "%.2f", stat.completionRate)),"
            csv += "\(String(format: "%.2f", stat.averageCompletionPercentage)),"
            csv += "\(avgTime)\n"
        }
        
        return csv
    }
    
    func generateEnrollmentSummaryReport(organizationId: String, startDate: Date, endDate: Date) async throws -> String {
        let allEnrollments: [Enrollment] = try await supabaseService.fetchAll(from: SupabaseConstants.enrollments)
        
        // Filter by date range
        let filteredEnrollments = allEnrollments.filter { enrollment in
            enrollment.enrollmentDate >= startDate && enrollment.enrollmentDate <= endDate
        }
        
        var csv = "Enrollment Summary Report\n"
        csv += "Generated: \(formatDateTime(Date()))\n"
        csv += "Period: \(formatDate(startDate)) to \(formatDate(endDate))\n\n"
        
        csv += "Enrollment ID,Learner ID,Course ID,Enrollment Date,Status,Completion %,Enrolled By,Last Accessed\n"
        
        for enrollment in filteredEnrollments.sorted(by: { $0.enrollmentDate > $1.enrollmentDate }) {
            csv += "\(enrollment.id ?? "N/A"),"
            csv += "\(enrollment.learnerId),"
            csv += "\(enrollment.courseId),"
            csv += "\(formatDate(enrollment.enrollmentDate)),"
            csv += "\(enrollment.status.displayName),"
            csv += "\(String(format: "%.1f", enrollment.completionPercentage)),"
            csv += "\(enrollment.enrolledBy ?? "self"),"
            csv += "\(enrollment.lastAccessed.map { formatDate($0) } ?? "Never")\n"
        }
        
        // Summary statistics
        csv += "\n\nSummary Statistics\n"
        csv += "Total Enrollments,\(filteredEnrollments.count)\n"
        csv += "Active,\(filteredEnrollments.filter { $0.status == .active }.count)\n"
        csv += "Completed,\(filteredEnrollments.filter { $0.status == .completed }.count)\n"
        csv += "Dropped,\(filteredEnrollments.filter { $0.status == .dropped }.count)\n"
        
        return csv
    }
    
    func generateLearnerProgressReport(organizationId: String) async throws -> String {
        let userMetrics = try await analyticsService.fetchUserActivityMetrics(organizationId: organizationId, role: .learner)
        
        var csv = "Learner Progress Report\n"
        csv += "Generated: \(formatDateTime(Date()))\n\n"
        
        csv += "Learner Name,Login Count,Last Login,Total Enrollments,Completed Courses,Learning Hours\n"
        
        for metric in userMetrics.sorted(by: { $0.totalLearningTimeHours > $1.totalLearningTimeHours }) {
            csv += "\"\(metric.userName)\","
            csv += "\(metric.loginCount),"
            csv += "\(metric.lastLogin.map { formatDate($0) } ?? "Never"),"
            csv += "\(metric.totalEnrollments),"
            csv += "\(metric.completedCourses),"
            csv += "\(String(format: "%.2f", metric.totalLearningTimeHours))\n"
        }
        
        return csv
    }
    
    func generateUserActivityReport(organizationId: String, startDate: Date, endDate: Date) async throws -> String {
        let users: [User] = try await supabaseService.query(
            from: SupabaseConstants.users,
            where: "organization_id",
            equals: organizationId
        )
        
        var csv = "User Activity Report\n"
        csv += "Generated: \(formatDateTime(Date()))\n"
        csv += "Period: \(formatDate(startDate)) to \(formatDate(endDate))\n\n"
        
        csv += "User Name,Email,Role,Login Count,Last Login,Active Status\n"
        
        for user in users.sorted(by: { $0.loginCount > $1.loginCount }) {
            let wasActiveInPeriod = user.lastLogin.map { $0 >= startDate && $0 <= endDate } ?? false
            
            csv += "\"\(user.fullName)\","
            csv += "\(user.email),"
            csv += "\(user.role.displayName),"
            csv += "\(user.loginCount),"
            csv += "\(user.lastLogin.map { formatDate($0) } ?? "Never"),"
            csv += "\(wasActiveInPeriod ? "Yes" : "No")\n"
        }
        
        // Summary
        csv += "\n\nSummary\n"
        csv += "Total Users,\(users.count)\n"
        csv += "Admins,\(users.filter { $0.role == .admin }.count)\n"
        csv += "Educators,\(users.filter { $0.role == .educator }.count)\n"
        csv += "Learners,\(users.filter { $0.role == .learner }.count)\n"
        csv += "Active Users,\(users.filter { $0.isActive }.count)\n"
        
        return csv
    }
    
    // MARK: - File Export
    
    func saveCSVToFile(_ csvContent: String, filename: String) -> URL? {
        let fileName = "\(filename)_\(formatFileDate(Date())).csv"
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try csvContent.write(to: path, atomically: true, encoding: .utf8)
            return path
        } catch {
            print("Error saving CSV file: \(error)")
            return nil
        }
    }
    
    func shareReport(type: ReportType, organizationId: String, startDate: Date = Date(), endDate: Date = Date()) async throws -> URL? {
        let csvContent: String
        
        switch type {
        case .platformUsage:
            csvContent = try await generatePlatformUsageReport(organizationId: organizationId)
        case .courseCompletion:
            csvContent = try await generateCourseCompletionReport(organizationId: organizationId)
        case .enrollmentSummary:
            csvContent = try await generateEnrollmentSummaryReport(organizationId: organizationId, startDate: startDate, endDate: endDate)
        case .learnerProgress:
            csvContent = try await generateLearnerProgressReport(organizationId: organizationId)
        case .userActivity:
            csvContent = try await generateUserActivityReport(organizationId: organizationId, startDate: startDate, endDate: endDate)
        }
        
        return saveCSVToFile(csvContent, filename: type.rawValue.replacingOccurrences(of: " ", with: "_"))
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatFileDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmm"
        return formatter.string(from: date)
    }
}
