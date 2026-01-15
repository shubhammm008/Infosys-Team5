//

//  ReportsView.swift

//  LTMS

//

//  Created by AI Assistant on 13/01/26.

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

                    

                    

                    // Report Preview

                    reportPreviewSection

                    

                    // Generate Button

                    generateButtonSection

                }

                .padding()

            }

            .background(Color.dashboardBg)

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

            VStack(spacing: 16) {

                Menu {

                    ForEach(ReportType.allCases, id: \.self) { type in

                        Button {

                            viewModel.selectedReportType = type

                        } label: {

                            Label(type.rawValue, systemImage: type.icon)

                        }

                    }

                } label: {

                    HStack(spacing: 12) {

                        Image(systemName: viewModel.selectedReportType.icon)

                            .foregroundColor(.accentPrimary)




                        Text(viewModel.selectedReportType.rawValue)

                            .foregroundColor(.dashboardTextPrimary)




                        Spacer()




                        Image(systemName: "chevron.down")

                            .foregroundColor(.dashboardTextSecondary)

                            .font(.caption)

                    }

                    .padding()

                    .frame(maxWidth: .infinity)   // ✅ NOW ACTUALLY FULL WIDTH

                    .background(Color.dashboardCardAlt)

                    .cornerRadius(12)

                }




                if needsDateRange {

                    dateRangeSection

                }

            }

            .padding()

            .background(Color.dashboardCard)

            .cornerRadius(16)

            .frame(maxWidth: .infinity)

        }

        

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

                                .foregroundColor(.dashboardTextSecondary)

                            Spacer()

                            Text(formatDate(viewModel.startDate))

                                .foregroundColor(.dashboardTextPrimary)

                            Image(systemName: showStartDatePicker ? "chevron.up" : "chevron.down")

                                .foregroundColor(.dashboardTextSecondary)

                                .font(.caption)

                        }

                        .padding()

                        .background(Color.dashboardCardAlt)

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

                                .foregroundColor(.dashboardTextSecondary)

                            Spacer()

                            Text(formatDate(viewModel.endDate))

                                .foregroundColor(.dashboardTextPrimary)

                            Image(systemName: showEndDatePicker ? "chevron.up" : "chevron.down")

                                .foregroundColor(.dashboardTextSecondary)

                                .font(.caption)

                        }

                        .padding()

                        .background(Color.dashboardCardAlt)

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

        .background(Color.dashboardBg)

        .cornerRadius(16)

    }

    

    @ViewBuilder

        private var reportPreviewSection: some View {

            VStack(alignment: .leading, spacing: 16) {

                Text("Report Details")

                    .font(.title2)

                    .fontWeight(.bold)

                

                VStack(alignment: .leading, spacing: 12) {

                    // Period Section (Only shows if applicable)

                    if needsDateRange {

                        HStack {

                            Image(systemName: "calendar")

                                .foregroundColor(.accentSecondary)

                            Text("Period: \(formatDate(viewModel.startDate)) - \(formatDate(viewModel.endDate))")

                                .font(.subheadline)

                        }

                        .padding()

                        .frame(maxWidth: .infinity, alignment: .leading)

                        .background(Color.dashboardCardAlt)

                        .cornerRadius(12)

                    }

                    

                    // Format Section

                    HStack {

                        Image(systemName: "doc.text")

                            .foregroundColor(.accentSuccess)

                        Text("Format: CSV (Excel compatible)")

                            .font(.subheadline)

                    }

                    .padding()

                    .frame(maxWidth: .infinity, alignment: .leading)

                    .background(Color.dashboardCardAlt)

                    .cornerRadius(12)

                    

                    // Info Section

                    HStack(alignment: .top) {

                        Image(systemName: "info.circle")

                            .foregroundColor(.accentWarning)

                        Text("The generated report will be saved to your device and can be shared via the system share sheet.")

                            .font(.caption)

                            .foregroundColor(.dashboardTextSecondary)

                    }

                    .padding(.horizontal)

                    .padding(.top, 4)

                }

            }

            .padding()

            .background(Color.dashboardCard)

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

                        .progressViewStyle(CircularProgressViewStyle(tint: .textOnAccent))

                    Text("Generating...")

                } else {

                    Image(systemName: "arrow.down.doc")

                    Text("Generate & Download Report")

                }

            }

            .frame(maxWidth: .infinity)

            .padding()

            .background(Color.accentPrimary)

            .foregroundColor(.textOnAccent)

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

                .foregroundColor(isSelected ? .accentPrimary : .dashboardTextSecondary)

                .frame(width: 40)

            

            VStack(alignment: .leading, spacing: 4) {

                Text(type.rawValue)

                    .font(.headline)

                    .foregroundColor(isSelected ? .primary : .secondary)

                

                Text(type.description)

                    .font(.caption)

                    .foregroundColor(.dashboardTextSecondary)

                    .lineLimit(2)

            }

            

            Spacer()

            

            if isSelected {

                Image(systemName: "checkmark.circle.fill")

                    .foregroundColor(.accentPrimary)

                    .font(.title3)

            }

        }

        .padding()

        .background(isSelected ? Color.accentPrimary.opacity(0.1) : Color.dashboardCardAlt)

        .overlay(

            RoundedRectangle(cornerRadius: 12)

                .stroke(isSelected ? Color.accentPrimary : Color.clear, lineWidth: 2)

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
