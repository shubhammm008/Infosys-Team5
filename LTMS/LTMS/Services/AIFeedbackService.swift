//
//  AIFeedbackService.swift
//  LTMS
//
//  Created by Assistant on 17/01/26.
//

import Foundation
import Combine

/// Service for AI-powered feedback and insights
@MainActor
class AIFeedbackService: ObservableObject {
    static let shared = AIFeedbackService()
    
    @Published var isLoading = false
    
    private init() {}
    
    // MARK: - AI Feedback Generation
    
    /// Generate personalized feedback based on quiz performance
    func generateQuizFeedback(
        score: Double,
        passed: Bool,
        courseTitle: String,
        quizTitle: String
    ) async -> String {
        // For now, using rule-based feedback
        // In production, this would integrate with Gemini/OpenAI API
        
        if passed {
            if score >= 95 {
                return "🌟 Outstanding performance on '\(quizTitle)'! You've demonstrated exceptional mastery of \(courseTitle). Consider challenging yourself with more advanced topics."
            } else if score >= 85 {
                return "🎯 Excellent work on '\(quizTitle)'! You have a strong grasp of the concepts in \(courseTitle). Keep up the great momentum!"
            } else if score >= 75 {
                return "✅ Good job on '\(quizTitle)'! You've passed and shown solid understanding. Review any challenging areas to strengthen your knowledge further."
            } else {
                return "👍 You passed '\(quizTitle)'! While you met the requirements, consider reviewing the material to deepen your understanding of \(courseTitle)."
            }
        } else {
            if score >= 60 {
                return "📚 You're close to passing '\(quizTitle)'! Review the course material, especially the topics you found challenging, and try again. You've got this!"
            } else if score >= 40 {
                return "💪 '\(quizTitle)' needs more preparation. Take time to revisit the lessons in \(courseTitle), practice the concepts, and attempt the quiz again when ready."
            } else {
                return "🔄 '\(quizTitle)' requires significant review. We recommend going through \(courseTitle) again, taking notes, and ensuring you understand each concept before retaking the quiz."
            }
        }
    }
    
    /// Generate learning insights based on progress
    func generateLearningInsights(statistics: LearningStatistics) async -> [String] {
        var insights: [String] = []
        
        // Completion rate insight
        if statistics.coursesCompleted > 0 {
            let completionRate = (Double(statistics.coursesCompleted) / Double(statistics.totalCoursesEnrolled)) * 100
            if completionRate >= 80 {
                insights.append("🏆 Impressive! You complete \(Int(completionRate))% of courses you start. Your dedication is outstanding!")
            } else if completionRate >= 50 {
                insights.append("📈 You complete about \(Int(completionRate))% of your courses. Try focusing on fewer courses at once to improve completion.")
            } else {
                insights.append("💡 Tip: You have \(statistics.coursesInProgress) courses in progress. Consider completing one before starting another.")
            }
        }
        
        // Quiz performance insight
        if statistics.quizzesTaken > 0 {
            if statistics.averageQuizScore >= 85 {
                insights.append("🎓 Your average quiz score of \(Int(statistics.averageQuizScore))% shows strong comprehension. You're ready for advanced topics!")
            } else if statistics.averageQuizScore >= 70 {
                insights.append("📊 Your quiz average is \(Int(statistics.averageQuizScore))%. Solid performance! Review incorrect answers to improve further.")
            } else {
                insights.append("📖 Your quiz average is \(Int(statistics.averageQuizScore))%. Take more time with course materials before attempting quizzes.")
            }
        }
        
        // Time spent insight
        let hours = statistics.totalTimeSpentSeconds / 3600
        if hours > 50 {
            insights.append("⏰ You've invested \(hours) hours in learning! Your commitment is paying off.")
        } else if hours > 20 {
            insights.append("⏱️ \(hours) hours of learning time logged. Keep building that knowledge!")
        }
        
        // Engagement insight
        if statistics.coursesInProgress > 3 {
            insights.append("🎯 You're juggling \(statistics.coursesInProgress) courses. Consider focusing on 2-3 for better retention.")
        }
        
        return insights
    }
    
    /// Generate personalized learning tips
    func generateLearningTips(profile: UserLearningProfile) async -> [String] {
        var tips: [String] = []
        
        // Based on quiz performance
        if profile.averageQuizScore < 70 {
            tips.append("Take notes while studying and review them before quizzes")
            tips.append("Break learning into smaller sessions for better retention")
        } else {
            tips.append("Challenge yourself with advanced courses to expand your skills")
            tips.append("Share your knowledge by helping other learners")
        }
        
        // Based on activity
        let daysSinceActive = Calendar.current.dateComponents([.day], from: profile.lastActiveDate, to: Date()).day ?? 0
        if daysSinceActive > 7 {
            tips.append("Consistency is key! Try to learn a little bit every day")
        } else if daysSinceActive <= 1 {
            tips.append("Great daily learning habit! Keep the momentum going")
        }
        
        // General tips
        tips.append("Set specific learning goals for each week")
        tips.append("Practice what you learn by building projects")
        
        return tips
    }
    
    /// Generate course recommendation explanation
    func explainRecommendation(recommendation: CourseRecommendation) -> String {
        switch recommendation.recommendationType {
        case .collaborative:
            return "Recommended because learners with similar interests found this valuable"
        case .contentBased:
            return "Matches your current skill level and learning progress"
        case .popular:
            return "Highly popular in your organization with great learner feedback"
        case .nextInPath:
            return "Next logical step in your learning journey"
        case .skillGap:
            return "Helps you develop skills to advance your career"
        }
    }
}
