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

    private let paymentMethods = [
        ("BANK_TRANSFER", "Bank Transfer"),
        ("CREDIT_CARD", "Credit Card"),
        ("CASH", "Cash"),
        ("CHECK", "Check"),
        ("OTHER", "Other")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Payment Details") {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)

                    DatePicker("Date", selection: $paymentDate, displayedComponents: .date)

                    TextField("Reference/Invoice #", text: $reference)
                }

                Section("Payment Method") {
                    Picker("Method", selection: $paymentMethod) {
                        ForEach(paymentMethods, id: \.0) { code, name in
                            Text(name).tag(code)
                        }
                    }
                    .pickerStyle(.menu)
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
                        // TODO: Record payment logic
                        // apiClient.post("/payments", data: ...)
                        isPresented = false
                    }
                    .disabled(amount.isEmpty)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Quick Payment Sheet") {
    QuickPaymentSheet(isPresented: .constant(true))
}
