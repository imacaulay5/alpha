//
//  CreateInvoiceSheet.swift
//  alpha
//
//  Created by Claude Code on 12/17/25.
//

import SwiftUI

struct CreateInvoiceSheet: View {
    @Binding var isPresented: Bool
    @State private var clientName = ""
    @State private var amount = ""
    @State private var dueDate = Date()
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Client Information") {
                    TextField("Client Name", text: $clientName)
                        .textContentType(.name)
                }

                Section("Invoice Details") {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)

                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)

                    TextField("Notes (Optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Create Invoice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        // TODO: Create invoice logic
                        // apiClient.post("/invoices", data: ...)
                        isPresented = false
                    }
                    .disabled(clientName.isEmpty || amount.isEmpty)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Create Invoice Sheet") {
    CreateInvoiceSheet(isPresented: .constant(true))
}
