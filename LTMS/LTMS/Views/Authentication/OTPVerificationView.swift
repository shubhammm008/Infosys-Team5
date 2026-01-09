//
//  OTPVerificationView.swift
//  LTMS
//
//  Created on 1/8/26.
//

import SwiftUI

struct OTPVerificationView: View {
    @StateObject private var authService = AuthService.shared
    @Environment(\.dismiss) private var dismiss
    
    let email: String
    
    @State private var otpCode: String = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isResending = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Header
            VStack(spacing: 12) {
                Image(systemName: "envelope.badge.shield.half.filled")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.ltmsPrimary, .ltmsSecondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Verify Your Email")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("We've sent a 6-digit code to")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(email)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.ltmsPrimary)
            }
            
            // OTP Input
            VStack(spacing: 8) {
                TextField("Enter 6-digit code", text: $otpCode)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .multilineTextAlignment(.center)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding()
                    .background(Color.ltmsCardBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(otpCode.count == 6 ? Color.ltmsPrimary : Color.gray.opacity(0.3), lineWidth: 2)
                    )
                    .onChange(of: otpCode) { newValue in
                        // Keep only digits and limit to 6
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered != newValue {
                            otpCode = filtered
                            return
                        }
                        if filtered.count > 6 {
                            otpCode = String(filtered.prefix(6))
                        }
                    }
            }
            .padding(.vertical)
            
            // Verify Button
            Button(action: verifyOTP) {
                HStack {
                    if authService.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Verify Code")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.ltmsPrimary, .ltmsSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(otpCode.count != 6 || authService.isLoading)
            .opacity(otpCode.count != 6 ? 0.6 : 1.0)
            
            // Resend Code
            Button(action: resendCode) {
                HStack(spacing: 4) {
                    if isResending {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text(isResending ? "Sending..." : "Didn't receive code? Resend")
                        .font(.subheadline)
                }
            }
            .disabled(isResending)
            
            Spacer()
        }
        .padding()
        .background(Color.ltmsBackground)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func verifyOTP() {
        Task {
            do {
                try await authService.verifyOTP(email: email, token: otpCode)
                // Success - user is now authenticated
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
                otpCode = "" // Clear incorrect code
            }
        }
    }
    
    private func resendCode() {
        Task {
            isResending = true
            defer { isResending = false }
            
            do {
                try await authService.resendOTP(email: email)
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

#Preview {
    OTPVerificationView(email: "user@example.com")
}
