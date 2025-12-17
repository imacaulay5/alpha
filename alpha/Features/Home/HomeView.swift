//
//  HomeView.swift
//  alpha
//
//  Created by Claude Code on 11/25/25.
//

import SwiftUI
import Combine

struct HomeMetrics: Codable {
    let hoursToday: Double
    let hoursWeek: Double
    let pendingExpensesCount: Int
    let pendingApprovalsCount: Int

    enum CodingKeys: String, CodingKey {
        case hoursToday = "hours_today"
        case hoursWeek = "hours_week"
        case pendingExpensesCount = "pending_expenses_count"
        case pendingApprovalsCount = "pending_approvals_count"
    }
}

@MainActor
class HomeViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var metrics: HomeMetrics?
    @Published var errorMessage: String?

    private let apiClient = APIClient.shared

    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            metrics = try await apiClient.get("/dashboard/metrics")
        } catch {
            errorMessage = "Failed to load metrics: \(error.localizedDescription)"
        }

        isLoading = false
    }
}

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = HomeViewModel()
    @State private var showingQuickEntry = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Hello, \(appState.currentUser?.name.components(separatedBy: " ").first ?? "User")!")
                                .font(.alphaHeadline)
                                .foregroundColor(.alphaPrimaryText)

                            Text("Here's your overview")
                                .font(.alphaBodySmall)
                                .foregroundColor(.alphaSecondaryText)
                        }

                        Spacer()

                        // Avatar
                        Circle()
                            .fill(Color.alphaPrimary)
                            .frame(width: 48, height: 48)
                            .overlay {
                                Text(appState.currentUser?.initials ?? "")
                                    .font(.alphaTitle)
                                    .foregroundColor(.white)
                            }
                    }
                    .padding(.horizontal)

                    // Metrics Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        MetricCard(
                            title: "Hours Today",
                            value: String(format: "%.1f", viewModel.metrics?.hoursToday ?? 0.0),
                            icon: "timer",
                            color: .blue
                        )

                        MetricCard(
                            title: "Hours This Week",
                            value: String(format: "%.1f", viewModel.metrics?.hoursWeek ?? 0.0),
                            icon: "calendar",
                            color: .green
                        )

                        MetricCard(
                            title: "Pending Expenses",
                            value: "\(viewModel.metrics?.pendingExpensesCount ?? 0)",
                            icon: "dollarsign.circle",
                            color: .orange
                        )

                        MetricCard(
                            title: "Pending Approvals",
                            value: "\(viewModel.metrics?.pendingApprovalsCount ?? 0)",
                            icon: "checkmark.circle",
                            color: .purple
                        )
                    }
                    .padding(.horizontal)

                    // Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.alphaTitle)
                            .foregroundColor(.alphaPrimaryText)
                            .padding(.horizontal)

                        VStack(spacing: 12) {
                            QuickActionButton(
                                title: "Log Time",
                                icon: "clock.fill",
                                color: .alphaPrimary
                            ) {
                                showingQuickEntry = true
                            }

                            QuickActionButton(
                                title: "Add Expense",
                                icon: "plus.circle.fill",
                                color: .alphaSecondary
                            ) {
                                // TODO: Navigate to expenses
                            }
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
            .sheet(isPresented: $showingQuickEntry) {
                QuickEntrySheet(isPresented: $showingQuickEntry)
            }
        }
    }
}

// MARK: - Metric Card

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.alphaDisplayLarge)
                    .foregroundColor(.alphaPrimaryText)

                Text(title)
                    .font(.alphaLabel)
                    .foregroundColor(.alphaSecondaryText)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.alphaCardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(color)
                    .cornerRadius(12)

                Text(title)
                    .font(.alphaBody)
                    .foregroundColor(.alphaPrimaryText)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.body)
                    .foregroundColor(.alphaSecondaryText)
            }
            .padding()
            .background(Color.alphaCardBackground)
            .cornerRadius(12)
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
