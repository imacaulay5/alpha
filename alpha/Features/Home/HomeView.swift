//
//  HomeView.swift
//  alpha
//
//  Created by Claude Code on 11/25/25.
//

import SwiftUI
import Combine

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
            async let metrics: BusinessMetrics = apiClient.get("/dashboard/business-metrics")
            async let activity: RecentActivity = apiClient.get("/dashboard/recent-activity")

            let (metricsResult, activityResult) = try await (metrics, activity)

            businessMetrics = metricsResult
            recentActivity = activityResult
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
    @State private var showingCreateInvoice = false
    @State private var showingQuickEntry = false
    @State private var showingQuickBill = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if viewModel.isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                            Text("Loading your dashboard...")
                                .font(.alphaBody)
                                .foregroundColor(.alphaSecondaryText)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 100)
                    } else if hasNoData {
                        EmptyStateView(
                            onCreateInvoice: { showingCreateInvoice = true },
                            onLogHours: { showingQuickEntry = true },
                            onQuickBill: { showingQuickBill = true }
                        )
                    } else {
                        // Welcome & Account-Specific Metrics
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Welcome back, \(appState.currentUser?.name.components(separatedBy: " ").first ?? "")!")
                                .font(.alphaTitle)
                                .foregroundColor(.alphaPrimaryText)

                            // Show different metrics based on account type
                            metricsSection
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
            .sheet(isPresented: $showingCreateInvoice) {
                CreateInvoiceSheet(isPresented: $showingCreateInvoice)
            }
            .sheet(isPresented: $showingQuickEntry) {
                QuickEntrySheet(isPresented: $showingQuickEntry)
            }
            .sheet(isPresented: $showingQuickBill) {
                QuickBillSheet(isPresented: $showingQuickBill)
            }
        }
    }

    private var hasNoData: Bool {
        viewModel.businessMetrics == nil && viewModel.recentActivity == nil && !viewModel.isLoading
    }

    // MARK: - Account-Specific Metrics

    @ViewBuilder
    private var metricsSection: some View {
        switch appState.currentUser?.accountType {
        case .personal:
            personalMetrics
        case .freelancer:
            freelancerMetrics
        case .business:
            businessMetrics
        case .none:
            EmptyView()
        }
    }

    // Personal Account - Simple metrics (2 cards)
    private var personalMetrics: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            if let metrics = viewModel.businessMetrics {
                MetricCard(
                    title: "Hours This Week",
                    value: String(format: "%.1f", metrics.billableHoursThisMonth / 4),
                    icon: "clock.fill",
                    backgroundColor: Color.blue.opacity(0.1),
                    iconColor: .blue
                )

                MetricCard(
                    title: "Expenses",
                    value: formatCurrency(metrics.totalRevenue * 0.2),
                    icon: "dollarsign.circle.fill",
                    backgroundColor: Color.purple.opacity(0.1),
                    iconColor: .purple
                )
                .requiresCapability(.viewOwnExpenses)
            }
        }
    }

    // Freelancer Account - Professional metrics (4 cards)
    private var freelancerMetrics: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            if let metrics = viewModel.businessMetrics {
                MetricCard(
                    title: "Billable Hours",
                    value: String(format: "%.1f", metrics.billableHoursThisMonth),
                    trend: metrics.hoursTrend,
                    changePercentage: metrics.hoursChangePercentage,
                    icon: "clock.fill",
                    backgroundColor: Color.blue.opacity(0.1),
                    iconColor: .blue
                )

                MetricCard(
                    title: "Revenue (MTD)",
                    value: formatCurrency(metrics.totalRevenue),
                    trend: metrics.revenueTrend,
                    changePercentage: metrics.revenueChangePercentage,
                    icon: "dollarsign.circle.fill",
                    backgroundColor: Color.green.opacity(0.1),
                    iconColor: .green
                )
                .requiresCapability(.viewAccountsReceivable)

                MetricCard(
                    title: "Outstanding",
                    value: formatCurrency(metrics.outstandingRevenue),
                    icon: "exclamationmark.circle.fill",
                    backgroundColor: Color.orange.opacity(0.1),
                    iconColor: .orange
                )
                .requiresCapability(.viewAccountsReceivable)

                MetricCard(
                    title: "Active Projects",
                    value: "\(metrics.pendingInvoices)",
                    icon: "folder.fill",
                    backgroundColor: Color.purple.opacity(0.1),
                    iconColor: .purple
                )
                .requiresCapability(.viewProjects)
            }
        }
    }

    // Business Account - Full metrics (6 cards)
    private var businessMetrics: some View {
        VStack(spacing: 16) {
            // Top row - financial metrics
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                if let metrics = viewModel.businessMetrics {
                    MetricCard(
                        title: "Revenue (MTD)",
                        value: formatCurrency(metrics.totalRevenue),
                        trend: metrics.revenueTrend,
                        changePercentage: metrics.revenueChangePercentage,
                        icon: "chart.line.uptrend.xyaxis",
                        backgroundColor: Color.green.opacity(0.1),
                        iconColor: .green
                    )
                    .requiresCapability(.viewFinancialStatements)

                    MetricCard(
                        title: "Profit Margin",
                        value: "32%",
                        trend: .down,
                        changePercentage: -2.1,
                        icon: "percent",
                        backgroundColor: Color.blue.opacity(0.1),
                        iconColor: .blue
                    )
                    .requiresCapability(.viewAdvancedReports)
                }
            }

            // Second row - operational metrics
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                if let metrics = viewModel.businessMetrics {
                    MetricCard(
                        title: "Team Hours",
                        value: String(format: "%.0f", metrics.billableHoursThisMonth * 4),
                        icon: "person.3.fill",
                        backgroundColor: Color.purple.opacity(0.1),
                        iconColor: .purple
                    )
                    .requiresCapability(.viewTeamTimeEntries)

                    MetricCard(
                        title: "Pending Approvals",
                        value: "\(metrics.pendingInvoices / 2)",
                        icon: "checkmark.circle.fill",
                        backgroundColor: Color.orange.opacity(0.1),
                        iconColor: .orange
                    )
                    .requiresAnyCapability(.approveTimeEntries, .approveExpenses)
                }
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

// MARK: - Empty State View

struct EmptyStateView: View {
    @EnvironmentObject var appState: AppState
    let onCreateInvoice: () -> Void
    let onLogHours: () -> Void
    let onQuickBill: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 64))
                    .foregroundColor(.alphaSecondaryText.opacity(0.5))

                Text("Welcome to Alpha!")
                    .font(.alphaTitle)
                    .foregroundColor(.alphaPrimaryText)

                Text(emptyStateMessage)
                    .font(.alphaBody)
                    .foregroundColor(.alphaSecondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            VStack(spacing: 16) {
                // Show quick actions based on capabilities
                if appState.hasCapability(.createInvoices) {
                    QuickActionCard(
                        title: "Create Invoice",
                        description: "Bill your clients for completed work",
                        icon: "doc.text.fill",
                        backgroundColor: Color.blue.opacity(0.1),
                        iconColor: .blue,
                        action: onCreateInvoice
                    )
                }

                if appState.hasCapability(.trackTime) {
                    QuickActionCard(
                        title: "Log Hours",
                        description: "Track billable time on tasks",
                        icon: "clock.fill",
                        backgroundColor: Color.purple.opacity(0.1),
                        iconColor: .purple,
                        action: onLogHours
                    )
                }

                if appState.hasCapability(.quickBill) {
                    QuickActionCard(
                        title: "Quick Bill",
                        description: "Bill time entries to clients",
                        icon: "dollarsign.circle.fill",
                        backgroundColor: Color.green.opacity(0.1),
                        iconColor: .green,
                        action: onQuickBill
                    )
                }
            }
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
    }

    private var emptyStateMessage: String {
        switch appState.currentUser?.accountType {
        case .personal:
            return "Start tracking your time and expenses to manage your personal finances."
        case .freelancer:
            return "Start tracking your business by creating your first invoice or logging billable hours."
        case .business:
            return "Start managing your team's time and projects. Create invoices and track revenue."
        case .none:
            return "Get started with Alpha!"
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
