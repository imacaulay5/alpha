//
//  BillingView.swift
//  alpha
//
//  Created by Claude Code on 12/16/25.
//

import SwiftUI
import Combine

// MARK: - ViewModel

@MainActor
class BillingViewModel: ObservableObject {
    @Published var outstandingInvoices: [Invoice] = []
    @Published var recentInvoices: [Invoice] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Summary metrics
    @Published var outstandingCount: Int = 0
    @Published var outstandingTotal: Double = 0
    @Published var pendingExpensesCount: Int = 0
    @Published var pendingExpensesTotal: Double = 0

    private let apiClient = APIClient.shared

    // MARK: - Public Methods

    func loadBillingData() async {
        isLoading = true
        errorMessage = nil

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadOutstandingInvoices() }
            group.addTask { await self.loadRecentInvoices() }
        }

        calculateSummaries()
        isLoading = false
    }

    // MARK: - Private Methods

    private func loadOutstandingInvoices() async {
        do {
            // Get SENT and OVERDUE invoices
            outstandingInvoices = try await apiClient.get("/invoices?status=SENT,OVERDUE")
        } catch {
            print("Failed to load outstanding invoices: \(error)")
            errorMessage = "Failed to load outstanding invoices"
            outstandingInvoices = []
        }
    }

    private func loadRecentInvoices() async {
        do {
            // Get last 5 paid invoices
            let allPaid: [Invoice] = try await apiClient.get("/invoices?status=PAID&limit=5")
            recentInvoices = allPaid
        } catch {
            print("Failed to load recent invoices: \(error)")
            errorMessage = "Failed to load recent invoices"
            recentInvoices = []
        }
    }

    private func calculateSummaries() {
        outstandingCount = outstandingInvoices.count
        outstandingTotal = outstandingInvoices.reduce(0) { $0 + $1.total }
    }
}

// MARK: - BillingView

struct BillingView: View {
    @StateObject private var viewModel = BillingViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Summary Cards
                    HStack(spacing: 12) {
                        BillingSummaryCard(
                            title: "Outstanding",
                            count: viewModel.outstandingCount,
                            total: viewModel.outstandingTotal,
                            icon: "doc.text",
                            color: .orange
                        )

                        BillingSummaryCard(
                            title: "Pending Expenses",
                            count: viewModel.pendingExpensesCount,
                            total: viewModel.pendingExpensesTotal,
                            icon: "dollarsign.circle",
                            color: .blue
                        )
                    }
                    .padding(.horizontal)

                    // Outstanding Invoices Section
                    if !viewModel.outstandingInvoices.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Outstanding Invoices")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.alphaPrimaryText)

                                Spacer()

                                Text("\(viewModel.outstandingCount)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.alphaSecondaryText)
                            }
                            .padding(.horizontal)

                            ForEach(viewModel.outstandingInvoices) { invoice in
                                InvoiceCard(invoice: invoice)
                                    .padding(.horizontal)
                            }
                        }
                    }

                    // Recent Invoices Section
                    if !viewModel.recentInvoices.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Recent Invoices")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.alphaPrimaryText)

                                Spacer()
                            }
                            .padding(.horizontal)

                            ForEach(viewModel.recentInvoices) { invoice in
                                InvoiceCard(invoice: invoice, compact: true)
                                    .padding(.horizontal)
                            }
                        }
                    }

                    // Empty State
                    if viewModel.outstandingInvoices.isEmpty && viewModel.recentInvoices.isEmpty && !viewModel.isLoading {
                        emptyState
                    }
                }
                .padding(.vertical)
            }
            .background(Color.alphaGroupedBackground)
            .navigationTitle("Billing")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await viewModel.loadBillingData()
            }
            .task {
                await viewModel.loadBillingData()
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.alphaSecondaryText)

            Text("No invoices yet")
                .font(.alphaBody)
                .foregroundColor(.alphaSecondaryText)

            Text("Invoices will appear here")
                .font(.alphaBodySmall)
                .foregroundColor(.alphaTertiaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

// MARK: - Billing Summary Card

struct BillingSummaryCard: View {
    let title: String
    let count: Int
    let total: Double
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)

                Spacer()

                Text("\(count)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.alphaPrimaryText)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.alphaSecondaryText)

                Text(String(format: "$%.2f", total))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.alphaPrimaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color.alphaCardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Invoice Card

struct InvoiceCard: View {
    let invoice: Invoice
    var compact: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            // Header Row
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(invoice.invoiceNumber)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.alphaPrimaryText)

                    if let client = invoice.client {
                        Text(client.name)
                            .font(.system(size: 14))
                            .foregroundColor(.alphaSecondaryText)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(invoice.totalFormatted)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.alphaPrimaryText)

                    statusBadge
                }
            }

            if !compact {
                Divider()

                // Details Row
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Due Date")
                            .font(.system(size: 12))
                            .foregroundColor(.alphaSecondaryText)

                        Text(invoice.dueDate, style: .date)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.alphaPrimaryText)
                    }

                    Spacer()

                    if invoice.isOverdue {
                        Label {
                            Text("Overdue by \(-invoice.daysUntilDue) days")
                                .font(.system(size: 12, weight: .medium))
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                        }
                        .foregroundColor(.alphaError)
                    } else if invoice.status == .sent {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Days Until Due")
                                .font(.system(size: 12))
                                .foregroundColor(.alphaSecondaryText)

                            Text("\(invoice.daysUntilDue)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.alphaPrimaryText)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.alphaCardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(invoice.isOverdue ? Color.alphaError.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }

    private var statusBadge: some View {
        Text(invoice.status.displayName)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor)
            .cornerRadius(6)
    }

    private var statusColor: Color {
        switch invoice.status {
        case .draft:
            return .gray
        case .sent:
            return .blue
        case .paid:
            return .green
        case .overdue:
            return .red
        case .cancelled:
            return .gray
        }
    }
}

// MARK: - Preview

#Preview("Billing View") {
    BillingView()
}
