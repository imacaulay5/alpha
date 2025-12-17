//
//  QuickBillSheet.swift
//  alpha
//
//  Created by Claude Code on 12/17/25.
//

import SwiftUI

struct QuickBillSheet: View {
    @Binding var isPresented: Bool
    @State private var amount = ""
    @State private var description = ""
    @State private var category = "OFFICE_SUPPLIES"
    @State private var expenseDate = Date()

    private let categories = [
        ("OFFICE_SUPPLIES", "Office Supplies"),
        ("TRAVEL", "Travel"),
        ("MEALS", "Meals"),
        ("SOFTWARE", "Software"),
        ("HARDWARE", "Hardware"),
        ("MARKETING", "Marketing"),
        ("UTILITIES", "Utilities"),
        ("OTHER", "Other")
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Bill Details") {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)

                    TextField("Description", text: $description)

                    DatePicker("Date", selection: $expenseDate, displayedComponents: .date)
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.0) { code, name in
                            Text(name).tag(code)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle("Quick Bill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // TODO: Save bill logic
                        // apiClient.post("/expenses", data: ...)
                        isPresented = false
                    }
                    .disabled(amount.isEmpty || description.isEmpty)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Quick Bill Sheet") {
    QuickBillSheet(isPresented: .constant(true))
}
