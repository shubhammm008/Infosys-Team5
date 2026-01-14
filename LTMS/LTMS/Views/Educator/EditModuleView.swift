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
            Form {
                Section("Module Information") {
                    TextField("Module Title", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Button("Save Changes") {
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
                    .disabled(title.isEmpty || description.isEmpty || isLoading)
                }
            }
            .navigationTitle("Edit Module")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "Failed to update module")
            }
        }
    }
}
