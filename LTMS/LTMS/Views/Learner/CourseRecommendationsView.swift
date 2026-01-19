//
//  CourseRecommendationsView.swift
//  LTMS
//
//  Created by Assistant on 17/01/26.
//

import SwiftUI
import Combine

struct CourseRecommendationsView: View {
    @StateObject private var viewModel = RecommendationsViewModel()
    @StateObject private var authService = SupabaseAuthService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recommended for You")
                    .font(.headline)
                    .foregroundColor(.dashboardTextPrimary)
                
                Spacer()
                
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.accentBlue)
                }
            }
            
            if viewModel.recommendations.isEmpty && !viewModel.isLoading {
                emptyState
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.recommendations) { recommendation in
                            RecommendationCard(recommendation: recommendation)
                        }
                    }
                }
            }
        }
        .task {
            if let userId = authService.currentUser?.id {
                await viewModel.loadRecommendations(userId: userId)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundColor(.dashboardTextSecondary)
            
            Text("Complete more courses to get personalized recommendations")
                .font(.subheadline)
                .foregroundColor(.dashboardTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct RecommendationCard: View {
    let recommendation: CourseRecommendation
    
    var body: some View {
        NavigationLink {
            CourseDetailView(course: recommendation.course)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                // Thumbnail
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [.accentBlue.opacity(0.6), .accentPurple.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 280, height: 140)
                    .overlay(
                        VStack {
                            Image(systemName: "sparkles")
                                .font(.system(size: 30))
                                .foregroundColor(.white.opacity(0.9))
                            
                            Text(recommendation.recommendationType.rawValue)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(8)
                        }
                    )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(recommendation.course.title)
                        .font(.headline)
                        .foregroundColor(.dashboardTextPrimary)
                        .lineLimit(2)
                    
                    Text(recommendation.reason)
                        .font(.caption)
                        .foregroundColor(.dashboardTextSecondary)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        Label("\(recommendation.course.durationHours)h", systemImage: "clock")
                            .font(.caption2)
                            .foregroundColor(.dashboardTextSecondary)
                        
                        Text(recommendation.course.level.displayName)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentBlue.opacity(0.2))
                            .foregroundColor(.accentBlue)
                            .cornerRadius(4)
                    }
                }
            }
            .frame(width: 280)
            .padding()
            .background(Color.dashboardCard)
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

@MainActor
class RecommendationsViewModel: ObservableObject {
    @Published var recommendations: [CourseRecommendation] = []
    @Published var isLoading = false
    
    func loadRecommendations(userId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            recommendations = try await RecommendationService.shared.getRecommendations(userId: userId, limit: 5)
        } catch {
            print("Error loading recommendations: \(error)")
        }
    }
}
