//
//  EditModuleView.swift
//  LTMS
//
//  Created by Shubham Singh on 07/01/26.
//

import SwiftUI

struct EditModuleView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ModuleLessonViewModel
    
    @State private var title: String
    @State private var description: String
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    init(viewModel: ModuleLessonViewModel) {
        self.viewModel = viewModel
        _title = State(initialValue: viewModel.module.title)
        _description = State(initialValue: viewModel.module.moduleDescription)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.dashboardBg.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button("Cancel") { dismiss() }
                            .foregroundColor(.dashboardTextSecondary)
                        Spacer()
                        Text("Edit Module")
                            .font(.headline)
                            .foregroundColor(.dashboardTextPrimary)
                        Spacer()
                        // Invisible button for balance
                        Button("Cancel") { }
                            .opacity(0)
                            .accessibilityHidden(true)
                    }
                    .padding()
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // Module Information Card
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Module Information")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.dashboardTextSecondary)
                                
                                VStack(spacing: 12) {
                                    customTextField(title: "Module Title", text: $title)
                                    customTextField(title: "Description", text: $description, isMultiline: true)
                                }
                            }
                            .padding()
                            .background(Color.dashboardCard)
                            .cornerRadius(20)
                            
                            // Save Button
                            Button(action: saveModule) {
                                ZStack {
                                    if isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Text("Save Changes")
                                            .fontWeight(.bold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    LinearGradient(
                                        colors: [Color.accentBlue, Color.accentPurple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(16)
                                .shadow(color: Color.accentBlue.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                            .disabled(title.isEmpty || description.isEmpty || isLoading)
                            .opacity(title.isEmpty || description.isEmpty || isLoading ? 0.6 : 1.0)
                        }
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "Failed to update module")
            }
        }
    }
    
    @ViewBuilder
    private func customTextField(title: String, text: Binding<String>, isMultiline: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.dashboardTextSecondary)
            
            if isMultiline {
                TextEditor(text: text)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 100)
                    .padding(12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .foregroundColor(.dashboardTextPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            } else {
                TextField(title, text: text)
                    .padding(12)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
                    .foregroundColor(.dashboardTextPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            }
        }
    }
    
    private func saveModule() {
        Task {
            isLoading = true
            defer { isLoading = false }
            do {
                try await viewModel.updateModule(title: title, description: description)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}
