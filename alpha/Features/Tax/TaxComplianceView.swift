//
//  TaxComplianceView.swift
//  alpha
//
//  Created by Claude Code on 01/12/26.
//

import SwiftUI
import Combine

@MainActor
class TaxComplianceViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var dashboard: TaxDashboard?
    @Published var errorMessage: String?

    private let taxRepository = TaxRepository()

    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            dashboard = try await taxRepository.fetchTaxDashboard()
        } catch {
            errorMessage = "Failed to load tax data: \(error.localizedDescription)"
        }

        isLoading = false
    }
}

struct TaxComplianceView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = TaxComplianceViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.isLoading {
                    loadingView
                } else if let dashboard = viewModel.dashboard {
                    VStack(spacing: 24) {
                        // Tax Summary Cards
                        taxSummarySection(dashboard)

                        // Tax-year records
                        taxRecordsSection(dashboard)

                        // Upcoming Deadlines
                        upcomingDeadlinesSection(dashboard)

                        // Recent Filings
                        recentFilingsSection(dashboard)
                    }
                    .padding()
                } else if let errorMessage = viewModel.errorMessage {
                    errorView(errorMessage)
                } else {
                    emptyStateView
                }
            }
            .background(Color.alphaGroupedBackground)
            .navigationTitle("Tax Compliance")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await viewModel.loadData()
            }
            .task {
                await viewModel.loadData()
            }
        }
    }

    // MARK: - Tax Summary Section

    @ViewBuilder
    private func taxSummarySection(_ dashboard: TaxDashboard) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tax Summary")
                .font(.alphaTitle)
                .foregroundColor(.alphaPrimaryText)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                // Tax Liability Card
                MetricCard(
                    title: "Tax Liability (YTD)",
                    value: formatCurrency(dashboard.taxLiability.yearToDate),
                    icon: "dollarsign.circle.fill",
                    backgroundColor: Color.red.opacity(0.1),
                    iconColor: .red
                )

                // Compliance Rate Card
                MetricCard(
                    title: "Compliance Rate",
                    value: String(format: "%.0f%%", dashboard.complianceRate.percentage),
                    icon: "checkmark.shield.fill",
                    backgroundColor: Color.green.opacity(0.1),
                    iconColor: .green
                )

                // Next Payment Card
                MetricCard(
                    title: "Next Payment",
                    value: formatCurrency(dashboard.taxLiability.nextPayment),
                    icon: "calendar.badge.exclamationmark",
                    backgroundColor: Color.orange.opacity(0.1),
                    iconColor: .orange
                )

                // Quarterly Estimate Card
                MetricCard(
                    title: "Quarterly Estimate",
                    value: formatCurrency(dashboard.taxLiability.estimatedQuarterly),
                    icon: "chart.bar.fill",
                    backgroundColor: Color.purple.opacity(0.1),
                    iconColor: .purple
                )
            }
        }
    }

    // MARK: - Tax Records Section

    @ViewBuilder
    private func taxRecordsSection(_ dashboard: TaxDashboard) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tax Prep Records")
                .font(.alphaTitle)
                .foregroundColor(.alphaPrimaryText)

            VStack(spacing: 0) {
                taxRecordRow(
                    title: "Expenses",
                    count: dashboard.taxExpenseCount,
                    value: dashboard.taxExpenseTotal,
                    icon: "receipt.fill",
                    tint: .orange
                )

                Divider()
                    .padding(.leading, 56)

                taxRecordRow(
                    title: "Income Records",
                    count: dashboard.taxIncomeCount,
                    value: dashboard.taxIncomeTotal,
                    icon: "doc.text.fill",
                    tint: .blue
                )

                Divider()
                    .padding(.leading, 56)

                HStack(spacing: 12) {
                    Image(systemName: dashboard.exportWarningCount == 0 ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .font(.title3)
                        .foregroundColor(dashboard.exportWarningCount == 0 ? .green : .orange)
                        .frame(width: 44, height: 44)
                        .background((dashboard.exportWarningCount == 0 ? Color.green : Color.orange).opacity(0.1))
                        .cornerRadius(10)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Readiness")
                            .font(.alphaHeadline)
                            .foregroundColor(.alphaPrimaryText)

                        Text(dashboard.exportWarningCount == 0 ? "Ready to review" : "\(dashboard.exportWarningCount) flags to review")
                            .font(.alphaBodySmall)
                            .foregroundColor(.alphaSecondaryText)
                    }

                    Spacer()
                }
                .padding()
            }
            .background(Color.alphaCardBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }

    private func taxRecordRow(title: String, count: Int, value: Double, icon: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(tint)
                .frame(width: 44, height: 44)
                .background(tint.opacity(0.1))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.alphaHeadline)
                    .foregroundColor(.alphaPrimaryText)

                Text("\(count) records")
                    .font(.alphaBodySmall)
                    .foregroundColor(.alphaSecondaryText)
            }

            Spacer()

            Text(formatCurrency(value))
                .font(.alphaHeadline)
                .foregroundColor(.alphaPrimaryText)
        }
        .padding()
    }

    // MARK: - Upcoming Deadlines Section

    @ViewBuilder
    private func upcomingDeadlinesSection(_ dashboard: TaxDashboard) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming Deadlines")
                .font(.alphaTitle)
                .foregroundColor(.alphaPrimaryText)

            if dashboard.upcomingDeadlines.isEmpty {
                emptyDeadlinesView
            } else {
                VStack(spacing: 0) {
                    ForEach(dashboard.upcomingDeadlines.prefix(5)) { deadline in
                        TaxDeadlineRow(deadline: deadline)
                            .padding(.vertical, 12)
                            .padding(.horizontal)

                        if deadline.id != dashboard.upcomingDeadlines.prefix(5).last?.id {
                            Divider()
                                .padding(.leading, 72)
                        }
                    }
                }
                .background(Color.alphaCardBackground)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            }
        }
    }

    // MARK: - Recent Filings Section

    @ViewBuilder
    private func recentFilingsSection(_ dashboard: TaxDashboard) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Filings")
                .font(.alphaTitle)
                .foregroundColor(.alphaPrimaryText)

            if dashboard.filings.isEmpty {
                emptyFilingsView
            } else {
                VStack(spacing: 0) {
                    ForEach(dashboard.filings.prefix(5)) { filing in
                        TaxFilingRow(filing: filing)
                            .padding(.vertical, 12)
                            .padding(.horizontal)

                        if filing.id != dashboard.filings.prefix(5).last?.id {
                            Divider()
                                .padding(.leading, 72)
                        }
                    }
                }
                .background(Color.alphaCardBackground)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            }
        }
    }

    // MARK: - Helper Views

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading tax data...")
                .font(.alphaBody)
                .foregroundColor(.alphaSecondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.plaintext")
                .font(.system(size: 64))
                .foregroundColor(.alphaSecondaryText.opacity(0.5))

            Text("No Tax Data Available")
                .font(.alphaTitle)
                .foregroundColor(.alphaPrimaryText)

            Text("Tax compliance data will appear here once you start tracking income and expenses.")
                .font(.alphaBody)
                .foregroundColor(.alphaSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 52))
                .foregroundColor(.orange)

            Text("Tax Prep Unavailable")
                .font(.alphaTitle)
                .foregroundColor(.alphaPrimaryText)

            Text(message)
                .font(.alphaBody)
                .foregroundColor(.alphaSecondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                Task {
                    await viewModel.loadData()
                }
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }

    private var emptyDeadlinesView: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title2)
            Text("All caught up! No upcoming deadlines.")
                .font(.alphaBody)
                .foregroundColor(.alphaSecondaryText)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.alphaCardBackground)
        .cornerRadius(12)
    }

    private var emptyFilingsView: some View {
        HStack {
            Image(systemName: "doc.text")
                .foregroundColor(.alphaSecondaryText)
                .font(.title2)
            Text("No filings recorded yet.")
                .font(.alphaBody)
                .foregroundColor(.alphaSecondaryText)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.alphaCardBackground)
        .cornerRadius(12)
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

// MARK: - Preview

#Preview("Tax Compliance") {
    TaxComplianceView()
        .environmentObject({
            let state = AppState()
            state.isAuthenticated = true
            state.currentUser = .freelancerPreview
            return state
        }())
}
