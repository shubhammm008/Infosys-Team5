//
//  LearnerActivityTimeline.swift
//  LTMS
//
//  Created by Assistant on 17/01/26.
//

import SwiftUI

struct LearnerActivityTimeline: View {
    let activities: [LearnerActivity]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .foregroundColor(.dashboardTextPrimary)
            
            if activities.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(activities) { activity in
                            ActivityRow(activity: activity)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.dashboardCard)
        .cornerRadius(20)
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 40))
                .foregroundColor(.dashboardTextSecondary)
            
            Text("No recent activity")
                .font(.subheadline)
                .foregroundColor(.dashboardTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct ActivityRow: View {
    let activity: LearnerActivity
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: activity.icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 40, height: 40)
                .background(iconColor.opacity(0.15))
                .clipShape(Circle())
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.description)
                    .font(.subheadline)
                    .foregroundColor(.dashboardTextPrimary)
                
                Text(timeAgo(from: activity.timestamp))
                    .font(.caption)
                    .foregroundColor(.dashboardTextSecondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.dashboardCardAlt.opacity(0.5))
        .cornerRadius(12)
    }
    
    private var iconColor: Color {
        switch activity.activityType {
        case .enrollment:
            return .accentBlue
        case .lessonComplete:
            return .green
        case .quizComplete:
            return .accentPurple
        case .courseComplete:
            return .orange
        case .login:
            return .gray
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return day == 1 ? "1 day ago" : "\(day) days ago"
        } else if let hour = components.hour, hour > 0 {
            return hour == 1 ? "1 hour ago" : "\(hour) hours ago"
        } else if let minute = components.minute, minute > 0 {
            return minute == 1 ? "1 minute ago" : "\(minute) minutes ago"
        } else {
            return "Just now"
        }
    }
}
