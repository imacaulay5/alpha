//
//  QuickPaymentSheet.swift
//  alpha
//
//  Created by Claude Code on 12/17/25.
//

import SwiftUI

struct QuickPaymentSheet: View {
    @Binding var isPresented: Bool
    @State private var amount = ""
    @State private var paymentMethod = "BANK_TRANSFER"
    @State private var reference = ""
    @State private var paymentDate = Date()
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private let paymentMethods = [
        ("BANK_TRANSFER", "Bank Transfer"),
        ("CREDIT_CARD", "Credit Card"),
        ("CASH", "Cash"),
        ("CHECK", "Check"),
        ("OTHER", "Other")
    ]

    private let paymentRepository = PaymentRepository()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)

                    DatePicker("Date", selection: $paymentDate, displayedComponents: .date)

                    TextField("Reference/Invoice #", text: $reference)
                } header: {
                    Text("Payment Details")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .textCase(nil)
                }

                Section {
                    Picker("Method", selection: $paymentMethod) {
                        ForEach(paymentMethods, id: \.0) { code, name in
                            Text(name).tag(code)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Payment Method")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .textCase(nil)
                }

                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Quick Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Record") {
                        Task {
                            await recordPayment()
                        }
                    }
                    .disabled(amount.isEmpty || isSubmitting)
                }
            }
        }
    }

    // MARK: - Payment Recording

    private func recordPayment() async {
        guard let amountValue = Double(amount), amountValue > 0 else {
            errorMessage = "Please enter a valid amount"
            return
        }

        isSubmitting = true
        errorMessage = nil

        do {
            _ = try await paymentRepository.createPayment(
                amount: amountValue,
                paymentMethod: paymentMethod,
                reference: reference,
                paymentDate: paymentDate
            )

            isPresented = false
        } catch {
            errorMessage = "Failed to record payment: \(error.localizedDescription)"
        }

        isSubmitting = false
    }
}

// MARK: - Preview

#Preview("Quick Payment Sheet") {
    QuickPaymentSheet(isPresented: .constant(true))
}
