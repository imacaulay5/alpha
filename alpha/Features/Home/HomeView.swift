//
//  HomeView.swift
//  alpha
//
//  Created by Claude Code on 11/25/25.
//

import SwiftUI
import Combine

// MARK: - Data Models

struct BusinessMetrics: Codable, Sendable {
    let totalRevenue: Double
    let revenueChangePercentage: Double
    let revenueTrend: TrendDirection

    let outstandingRevenue: Double
    let outstandingChangePercentage: Double
    let outstandingTrend: TrendDirection

    let billableHoursThisMonth: Double
    let hoursChangePercentage: Double
    let hoursTrend: TrendDirection

    let pendingInvoices: Int
    let invoicesChangePercentage: Double
    let invoicesTrend: TrendDirection

    enum CodingKeys: String, CodingKey {
        case totalRevenue = "total_revenue"
        case revenueChangePercentage = "revenue_change_percentage"
        case revenueTrend = "revenue_trend"
        case outstandingRevenue = "outstanding_revenue"
        case outstandingChangePercentage = "outstanding_change_percentage"
        case outstandingTrend = "outstanding_trend"
        case billableHoursThisMonth = "billable_hours_this_month"
        case hoursChangePercentage = "hours_change_percentage"
        case hoursTrend = "hours_trend"
        case pendingInvoices = "pending_invoices"
        case invoicesChangePercentage = "invoices_change_percentage"
        case invoicesTrend = "invoices_trend"
    }
}

struct RecentActivity: Codable, Sendable {
    let activities: [ActivityItem]
}

// MARK: - View Model

@MainActor
class HomeViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var businessMetrics: BusinessMetrics?
    @Published var recentActivity: RecentActivity?
    @Published var errorMessage: String?

    private let apiClient = APIClient.shared

    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load metrics and activity in parallel
            async let metricsTask: BusinessMetrics = apiClient.get("/dashboard/business-metrics")
            async let activityTask: RecentActivity = apiClient.get("/dashboard/recent-activity")

            businessMetrics = try await metricsTask
            recentActivity = try await activityTask
        } catch {
            errorMessage = "Failed to load dashboard data: \(error.localizedDescription)"
        }

        isLoading = false
    }
}

// MARK: - Home View

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome & Business Metrics
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Welcome back!")
                            .font(.alphaTitle)
                            .foregroundColor(.alphaPrimaryText)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            if let metrics = viewModel.businessMetrics {
                                MetricCard(
                                    title: "Total Revenue",
                                    value: formatCurrency(metrics.totalRevenue),
                                    trend: metrics.revenueTrend,
                                    changePercentage: metrics.revenueChangePercentage,
                                    icon: "dollarsign.circle.fill",
                                    backgroundColor: Color.green.opacity(0.1),
                                    iconColor: .green
                                )

                                MetricCard(
                                    title: "Outstanding Revenue",
                                    value: formatCurrency(metrics.outstandingRevenue),
                                    trend: metrics.outstandingTrend,
                                    changePercentage: metrics.outstandingChangePercentage,
                                    icon: "exclamationmark.circle.fill",
                                    backgroundColor: Color.orange.opacity(0.1),
                                    iconColor: .orange
                                )

                                MetricCard(
                                    title: "Billable Hours",
                                    value: String(format: "%.1f", metrics.billableHoursThisMonth),
                                    trend: metrics.hoursTrend,
                                    changePercentage: metrics.hoursChangePercentage,
                                    icon: "clock.fill",
                                    backgroundColor: Color.purple.opacity(0.1),
                                    iconColor: .purple
                                )

                                MetricCard(
                                    title: "Pending Invoices",
                                    value: "\(metrics.pendingInvoices)",
                                    trend: metrics.invoicesTrend,
                                    changePercentage: metrics.invoicesChangePercentage,
                                    icon: "doc.text.fill",
                                    backgroundColor: Color.blue.opacity(0.1),
                                    iconColor: .blue
                                )
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Recent Activity
                    if let activities = viewModel.recentActivity?.activities, !activities.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Activity")
                                .font(.alphaTitle)
                                .foregroundColor(.alphaPrimaryText)

                            VStack(spacing: 0) {
                                ForEach(activities) { activity in
                                    ActivityItemRow(activity: activity)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal)

                                    if activity.id != activities.last?.id {
                                        Divider()
                                            .padding(.leading, 56)
                                    }
                                }
                            }
                            .background(Color.alphaCardBackground)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                        }
                        .padding(.horizontal)
                    }

                    Spacer()
                }
                .padding(.vertical)
            }
            .background(Color.alphaGroupedBackground)
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await viewModel.loadData()
            }
            .task {
                await viewModel.loadData()
            }
        }
    }

    // MARK: - Helper Functions

    private func formatCurrency(_ value: Double) -> String {
        if value >= 1_000_000 {
            return String(format: "$%.1fM", value / 1_000_000)
        } else if value >= 1_000 {
            return String(format: "$%.1fK", value / 1_000)
        } else {
            return String(format: "$%.0f", value)
        }
    }
}

// MARK: - Preview

#Preview("Home") {
    HomeView()
        .environmentObject({
            let state = AppState()
            state.isAuthenticated = true
            state.currentUser = .preview
            state.organization = .preview
            return state
        }())
}
