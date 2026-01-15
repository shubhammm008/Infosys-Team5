//
//  LTMSInputField.swift
//  LTMS
//
//  Created for Admin Theme Visibility Fix
//

import SwiftUI

struct LTMSInputField: View {
    let title: String
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.dashboardTextSecondary)
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.dashboardTextSecondary)
                    .frame(width: 20)
                
                if isSecure {
                    ZStack(alignment: .leading) {
                        if text.isEmpty {
                            Text(placeholder)
                                .foregroundColor(.dashboardTextSecondary.opacity(0.5))
                        }
                        SecureField("", text: $text)
                            .foregroundColor(.dashboardTextPrimary)
                            .tint(.accentPrimary)
                    }
                } else {
                    ZStack(alignment: .leading) {
                        if text.isEmpty {
                            Text(placeholder)
                                .foregroundColor(.dashboardTextSecondary.opacity(0.5))
                        }
                        TextField("", text: $text)
                            .keyboardType(keyboardType)
                            .autocapitalization(keyboardType == .emailAddress ? .none : .words)
                            .foregroundColor(.dashboardTextPrimary)
                            .tint(.accentPrimary)
                    }
                }
            }
            .padding()
            .background(Color.dashboardCard)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.dashboardCardAlt, lineWidth: 1)
            )
        }
    }
}

#Preview {
    ZStack {
        Color.dashboardBg.ignoresSafeArea()
        VStack(spacing: 20) {
            LTMSInputField(
                title: "Email",
                icon: "envelope.fill",
                placeholder: "Enter your email",
                text: .constant("")
            )
            
            LTMSInputField(
                title: "Password",
                icon: "lock.fill",
                placeholder: "Enter password",
                text: .constant("Secret"),
                isSecure: true
            )
        }
        .padding()
    }
}
