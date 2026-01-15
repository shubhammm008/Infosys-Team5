//
//  TermsPrivacyView.swift
//  LTMS
//
//  Created by Assistant on 15/01/26.
//

import SwiftUI

struct TermsPrivacyView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Segmented Control
                Picker("", selection: $selectedTab) {
                    Text("Terms of Service").tag(0)
                    Text("Privacy Policy").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content
                TabView(selection: $selectedTab) {
                    TermsOfServiceView()
                        .tag(0)
                    
                    PrivacyPolicyView()
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Legal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
        }
    }
}

// MARK: - Terms of Service View

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Terms of Service")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Last updated: January 15, 2026")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 8)
                
                // Introduction
                SectionView(
                    title: "1. Introduction",
                    content: """
                    Welcome to the Learning & Training Management System (LTMS). By accessing or using our platform, you agree to be bound by these Terms of Service. Please read them carefully.
                    
                    LTMS provides a comprehensive learning platform for educators and learners to create, share, and access educational content.
                    """
                )
                
                // User Accounts
                SectionView(
                    title: "2. User Accounts",
                    content: """
                    To access certain features of LTMS, you must create an account. You agree to:
                    
                    • Provide accurate and complete information
                    • Maintain the security of your account credentials
                    • Notify us immediately of any unauthorized access
                    • Be responsible for all activities under your account
                    
                    We reserve the right to suspend or terminate accounts that violate these terms.
                    """
                )
                
                // User Conduct
                SectionView(
                    title: "3. User Conduct",
                    content: """
                    You agree not to:
                    
                    • Upload malicious or harmful content
                    • Violate intellectual property rights
                    • Harass or abuse other users
                    • Attempt to bypass security measures
                    • Use the platform for illegal activities
                    • Share your account credentials with others
                    """
                )
                
                // Content Rights
                SectionView(
                    title: "4. Content and Intellectual Property",
                    content: """
                    Educators retain ownership of the content they create and upload. By uploading content, you grant LTMS a license to:
                    
                    • Host and distribute your content on the platform
                    • Display your content to enrolled learners
                    • Create derivative works for platform functionality
                    
                    You represent that you have the right to upload all content and that it doesn't infringe on third-party rights.
                    """
                )
                
                // Payment Terms
                SectionView(
                    title: "5. Payment and Refunds",
                    content: """
                    Certain courses may require payment. By purchasing a course, you agree to:
                    
                    • Pay all applicable fees
                    • Provide valid payment information
                    • Accept our refund policy
                    
                    Refund requests must be made within 14 days of purchase. Once course content is accessed, refunds may be limited.
                    """
                )
                
                // Disclaimer
                SectionView(
                    title: "6. Disclaimer of Warranties",
                    content: """
                    LTMS is provided "as is" without warranties of any kind. We do not guarantee:
                    
                    • Uninterrupted or error-free service
                    • Accuracy or completeness of content
                    • Achievement of learning outcomes
                    • Compatibility with all devices
                    """
                )
                
                // Limitation of Liability
                SectionView(
                    title: "7. Limitation of Liability",
                    content: """
                    To the maximum extent permitted by law, LTMS shall not be liable for:
                    
                    • Indirect or consequential damages
                    • Loss of data or profits
                    • Service interruptions
                    • Third-party actions
                    
                    Our total liability shall not exceed the amount you paid in the last 12 months.
                    """
                )
                
                // Changes to Terms
                SectionView(
                    title: "8. Changes to Terms",
                    content: """
                    We reserve the right to modify these terms at any time. We will notify users of significant changes via email or platform notification. Continued use after changes constitutes acceptance of the new terms.
                    """
                )
                
                // Contact
                SectionView(
                    title: "9. Contact Information",
                    content: """
                    If you have questions about these Terms of Service, please contact us at:
                    
                    Email: legal@ltms.com
                    Address: 123 Education Street, Learning City, LC 12345
                    """
                )
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Privacy Policy View

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Privacy Policy")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Last updated: January 15, 2026")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 8)
                
                // Introduction
                SectionView(
                    title: "1. Information We Collect",
                    content: """
                    We collect information to provide and improve our services:
                    
                    Personal Information:
                    • Name and email address
                    • Phone number (optional)
                    • Profile information
                    • Payment information
                    
                    Usage Information:
                    • Course enrollment and progress
                    • Quiz scores and completion rates
                    • Platform interaction data
                    • Device and browser information
                    """
                )
                
                // How We Use Information
                SectionView(
                    title: "2. How We Use Your Information",
                    content: """
                    We use your information to:
                    
                    • Provide and maintain the platform
                    • Process enrollments and payments
                    • Send important notifications
                    • Improve user experience
                    • Analyze platform usage
                    • Prevent fraud and abuse
                    • Comply with legal obligations
                    
                    We will never sell your personal information to third parties.
                    """
                )
                
                // Data Sharing
                SectionView(
                    title: "3. Data Sharing and Disclosure",
                    content: """
                    We may share your information with:
                    
                    Service Providers:
                    • Cloud hosting providers
                    • Payment processors
                    • Analytics services
                    
                    Legal Requirements:
                    • When required by law
                    • To protect our rights
                    • To prevent fraud
                    
                    Within Platform:
                    • Course creators can see enrolled learner names
                    • Progress data visible to educators for enrolled courses
                    """
                )
                
                // Data Security
                SectionView(
                    title: "4. Data Security",
                    content: """
                    We implement industry-standard security measures:
                    
                    • Encrypted data transmission (SSL/TLS)
                    • Secure data storage
                    • Regular security audits
                    • Access controls and authentication
                    • Employee training on data protection
                    
                    However, no system is completely secure. We cannot guarantee absolute security.
                    """
                )
                
                // Your Rights
                SectionView(
                    title: "5. Your Rights and Choices",
                    content: """
                    You have the right to:
                    
                    • Access your personal information
                    • Correct inaccurate data
                    • Request data deletion
                    • Opt-out of marketing communications
                    • Export your data
                    • Withdraw consent
                    
                    To exercise these rights, contact us at privacy@ltms.com
                    """
                )
                
                // Data Retention
                SectionView(
                    title: "6. Data Retention",
                    content: """
                    We retain your information for as long as necessary to:
                    
                    • Provide services
                    • Comply with legal obligations
                    • Resolve disputes
                    • Enforce agreements
                    
                    After account deletion, we may retain certain information for legal or legitimate business purposes.
                    """
                )
                
                // Children's Privacy
                SectionView(
                    title: "7. Children's Privacy",
                    content: """
                    LTMS is not intended for users under 13 years of age. We do not knowingly collect information from children under 13.
                    
                    If you believe we have collected information from a child under 13, please contact us immediately at privacy@ltms.com
                    """
                )
                
                // Cookies
                SectionView(
                    title: "8. Cookies and Tracking",
                    content: """
                    We use cookies and similar technologies to:
                    
                    • Maintain user sessions
                    • Remember preferences
                    • Analyze platform usage
                    • Improve functionality
                    
                    You can control cookies through your browser settings, but some features may not work properly if disabled.
                    """
                )
                
                // International Transfers
                SectionView(
                    title: "9. International Data Transfers",
                    content: """
                    Your information may be transferred to and processed in countries other than your own. We ensure appropriate safeguards are in place to protect your data in accordance with this privacy policy.
                    """
                )
                
                // Policy Changes
                SectionView(
                    title: "10. Changes to This Policy",
                    content: """
                    We may update this privacy policy from time to time. We will notify you of significant changes via email or platform notification. Your continued use after changes constitutes acceptance.
                    """
                )
                
                // Contact
                SectionView(
                    title: "11. Contact Us",
                    content: """
                    For privacy-related questions or concerns:
                    
                    Email: privacy@ltms.com
                    Data Protection Officer: dpo@ltms.com
                    Address: 123 Education Street, Learning City, LC 12345
                    """
                )
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Supporting Component

struct SectionView: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(content)
                .font(.body)
                .foregroundColor(.primary)
                .lineSpacing(4)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    TermsPrivacyView()
}
