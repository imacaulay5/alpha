//
//  ExpenseView.swift
//  alpha
//
//  Created by Claude Code on 11/25/25.
//

import SwiftUI
import Combine

@MainActor
class ExpenseViewModel: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var isLoading = false
    @Published var showingAddExpense = false
    @Published var errorMessage: String?

    private let apiClient = APIClient.shared

    var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    var pendingCount: Int {
        expenses.filter { $0.status == .submitted }.count
    }

    func loadExpenses() async {
        isLoading = true
        errorMessage = nil

        do {
            expenses = try await apiClient.get("/expenses")
        } catch {
            errorMessage = "Failed to load expenses: \(error.localizedDescription)"
            expenses = []
        }

        isLoading = false
    }

    func deleteExpense(_ expenseId: String) async {
        do {
            let _: [String: Bool] = try await apiClient.delete("/expenses/\(expenseId)")
            await loadExpenses()
        } catch {
            errorMessage = "Failed to delete expense: \(error.localizedDescription)"
        }
    }
}

struct ExpenseView: View {
    @StateObject private var viewModel = ExpenseViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Summary Card
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Expenses")
                                .font(.alphaLabel)
                                .foregroundColor(.alphaSecondaryText)

                            Text(String(format: "$%.2f", viewModel.totalExpenses))
                                .font(.alphaDisplayLarge)
                                .foregroundColor(.alphaPrimaryText)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Pending")
                                .font(.alphaLabel)
                                .foregroundColor(.alphaSecondaryText)

                            Text("\(viewModel.pendingCount)")
                                .font(.alphaHeadline)
                                .foregroundColor(.alphaWarning)
                        }
                    }
                    .padding()
                    .background(Color.alphaCardBackground)
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Expenses List
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Expenses")
                            .font(.alphaTitle)
                            .foregroundColor(.alphaPrimaryText)
                            .padding(.horizontal)

                        if viewModel.expenses.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "dollarsign.circle")
                                    .font(.system(size: 48))
                                    .foregroundColor(.alphaSecondaryText)

                                Text("No expenses yet")
                                    .font(.alphaBody)
                                    .foregroundColor(.alphaSecondaryText)

                                Text("Tap the + button to add your first expense")
                                    .font(.alphaBodySmall)
                                    .foregroundColor(.alphaTertiaryText)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 48)
                        } else {
                            // TODO: Display expenses
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color.alphaGroupedBackground)
            .navigationTitle("Expenses")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await viewModel.loadExpenses()
            }
            .task {
                await viewModel.loadExpenses()
            }
            .sheet(isPresented: $viewModel.showingAddExpense) {
                Text("Add Expense Form")
                    .font(.alphaHeadline)
                // TODO: Implement add expense form
            }
        }
    }
}

// MARK: - Preview

#Preview("Expenses") {
    ExpenseView()
}
