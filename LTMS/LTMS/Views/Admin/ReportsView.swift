//
//  ReportsView.swift
//  LTMS
//
//  Created by Shubham Singh on 13/01/26.
//

import SwiftUI
import Combine
import UniformTypeIdentifiers

@MainActor
class ReportsViewModel: ObservableObject {
    @Published var selectedReportType: ReportType = .platformUsage
    @Published var startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    @Published var endDate = Date()
    @Published var isGenerating = false
    @Published var errorMessage: String?
    @Published var showShareSheet = false
    @Published var reportURL: URL?
    
    private let reportService = ReportService()
    
    func generateReport(organizationId: String) async {
        isGenerating = true
        errorMessage = nil
        
        do {
            reportURL = try await reportService.shareReport(
                type: selectedReportType,
                organizationId: organizationId,
                startDate: startDate,
                endDate: endDate
            )
            
            if reportURL != nil {
                showShareSheet = true
            } else {
                errorMessage = "Failed to generate report file"
            }
        } catch {
            errorMessage = "Error generating report: \(error.localizedDescription)"
        }
        
        isGenerating = false
    }
}

struct ReportsView: View {
    @StateObject private var viewModel = ReportsViewModel()
    @EnvironmentObject var authService: SupabaseAuthService
    @State private var showStartDatePicker = false
    @State private var showEndDatePicker = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Report Type Selection
                    reportTypeSection
                    
                    // Date Range (for applicable reports)
                    if needsDateRange {
                        dateRangeSection
                    }
                    
                    // Report Preview
                    reportPreviewSection
                    
                    // Generate Button
                    generateButtonSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Generate Reports")
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .sheet(isPresented: $viewModel.showShareSheet) {
                if let url = viewModel.reportURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }
    
    private var needsDateRange: Bool {
        viewModel.selectedReportType == .enrollmentSummary || viewModel.selectedReportType == .userActivity
    }
    
    @ViewBuilder
    private var reportTypeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Report Type")
                .font(.title2)
                .fontWeight(.bold)
            
            ForEach(ReportType.allCases, id: \.self) { type in
                ReportTypeCard(
                    type: type,
                    isSelected: viewModel.selectedReportType == type
                )
                .onTapGesture {
                    viewModel.selectedReportType = type
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    @ViewBuilder
    private var dateRangeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Date Range")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                // Start Date
                VStack(spacing: 0) {
                    Button(action: {
                        withAnimation {
                            showEndDatePicker = false
                            showStartDatePicker.toggle()
                        }
                    }) {
                        HStack {
                            Text("Start Date")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatDate(viewModel.startDate))
                                .foregroundColor(.primary)
                            Image(systemName: showStartDatePicker ? "chevron.up" : "chevron.down")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    if showStartDatePicker {
                        DatePicker(
                            "",
                            selection: $viewModel.startDate,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .padding(.horizontal)
                        .transition(.opacity)
                        .onChange(of: viewModel.startDate) { newValue in
                            // Ensure end date is not before start date
                            if viewModel.endDate < newValue {
                                viewModel.endDate = newValue
                            }
                        }
                    }
                }
                
                // End Date
                VStack(spacing: 0) {
                    Button(action: {
                        withAnimation {
                            showStartDatePicker = false
                            showEndDatePicker.toggle()
                        }
                    }) {
                        HStack {
                            Text("End Date")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatDate(viewModel.endDate))
                                .foregroundColor(.primary)
                            Image(systemName: showEndDatePicker ? "chevron.up" : "chevron.down")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    if showEndDatePicker {
                        DatePicker(
                            "",
                            selection: $viewModel.endDate,
                            in: viewModel.startDate...Date(),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .padding(.horizontal)
                        .transition(.opacity)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    @ViewBuilder
    private var reportPreviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Report Details")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: viewModel.selectedReportType.icon)
                        .foregroundColor(.blue)
                        .font(.title)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.selectedReportType.rawValue)
                            .font(.headline)
                        Text(viewModel.selectedReportType.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                if needsDateRange {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.purple)
                        Text("Period: \(formatDate(viewModel.startDate)) - \(formatDate(viewModel.endDate))")
                            .font(.subheadline)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                }
                
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(.green)
                    Text("Format: CSV (Excel compatible)")
                        .font(.subheadline)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.orange)
                    Text("Report will be saved to your device and can be shared")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
    
    @ViewBuilder
    private var generateButtonSection: some View {
        Button(action: {
            Task {
                if let organizationId = authService.currentUser?.organizationId {
                    await viewModel.generateReport(organizationId: organizationId)
                }
            }
        }) {
            HStack {
                if viewModel.isGenerating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text("Generating...")
                } else {
                    Image(systemName: "arrow.down.doc")
                    Text("Generate & Download Report")
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .fontWeight(.semibold)
        }
        .disabled(viewModel.isGenerating)
        .padding(.horizontal)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy"
        return formatter.string(from: date)
    }
}

struct ReportTypeCard: View {
    let type: ReportType
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: type.icon)
                .font(.title2)
                .foregroundColor(isSelected ? .blue : .gray)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(type.rawValue)
                    .font(.headline)
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                Text(type.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
            }
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .cornerRadius(12)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ReportsView()
        .environmentObject(SupabaseAuthService.shared)
}
