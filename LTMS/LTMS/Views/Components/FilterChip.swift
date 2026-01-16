//
//  FilterChip.swift
//  LTMS
//
//  Created by GitHub Copilot on 16/01/26.
//

import SwiftUI

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected
                    ? LinearGradient(
                        colors: [.ltmsPrimary, .ltmsSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    : LinearGradient(
                        colors: [Color.ltmsCardBackground, Color.ltmsCardBackground],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}
