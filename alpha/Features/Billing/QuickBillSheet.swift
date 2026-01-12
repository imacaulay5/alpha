//
//  QuickBillSheet.swift
//  alpha
//
//  Created by Claude Code on 12/17/25.
//

import SwiftUI

struct QuickBillSheet: View {
    @Binding var isPresented: Bool
    @State private var selectedVendor: Contact?
    @State private var contacts: [Contact] = []
    @State private var isLoadingContacts = false
    @State private var lineItems: [BillLineItem] = [BillLineItem()]
    @State private var expenseDate = Date()
    @State private var showingNewContact = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private let apiClient = APIClient.shared

    // Request structure matching backend schema
    private struct CreateExpenseRequest: Codable {
        let expenseDate: String
        let lineItems: [ExpenseLineItemRequest]
        let currency: String

        enum CodingKeys: String, CodingKey {
            case expenseDate = "expense_date"
            case lineItems = "line_items"
            case currency
        }
    }

    private struct ExpenseLineItemRequest: Codable {
        let description: String
        let amount: Double
        let category: String
    }

    private struct ExpenseResponse: Codable {
        let id: String
    }

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

    private var totalAmount: Double {
        lineItems.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if isLoadingContacts {
                        HStack {
                            ProgressView()
                            Text("Loading contacts...")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Picker("Select Vendor", selection: $selectedVendor) {
                            Text("Select a vendor").tag(nil as Contact?)
                            ForEach(contacts) { contact in
                                Text(contact.name).tag(contact as Contact?)
                            }
                        }

                        Button(action: { showingNewContact = true }) {
                            Label("Add New Vendor", systemImage: "plus.circle.fill")
                        }

                        if let vendor = selectedVendor {
                            VStack(alignment: .leading, spacing: 8) {
                                if let email = vendor.email {
                                    Label(email, systemImage: "envelope")
                                        .font(.alphaBodySmall)
                                        .foregroundColor(.alphaSecondaryText)
                                }
                                if let phone = vendor.phone {
                                    Label(phone, systemImage: "phone")
                                        .font(.alphaBodySmall)
                                        .foregroundColor(.alphaSecondaryText)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Vendor Information")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .textCase(nil)
                }

                Section {
                    ForEach($lineItems) { $item in
                        VStack(spacing: 12) {
                            TextField("Description", text: $item.description)
                                .font(.alphaBody)

                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Amount")
                                        .font(.alphaCaption)
                                        .foregroundColor(.alphaSecondaryText)
                                    TextField("0.00", value: $item.amount, format: .currency(code: "USD"))
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(.roundedBorder)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Category")
                                        .font(.alphaCaption)
                                        .foregroundColor(.alphaSecondaryText)
                                    Picker("Category", selection: $item.category) {
                                        ForEach(categories, id: \.0) { code, name in
                                            Text(name).tag(code)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }
                            }

                            if lineItems.count > 1 {
                                Button(role: .destructive, action: {
                                    removeLineItem(item)
                                }) {
                                    Label("Remove Item", systemImage: "trash")
                                        .font(.alphaBodySmall)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    Button(action: addLineItem) {
                        Label("Add Line Item", systemImage: "plus.circle.fill")
                    }

                    HStack {
                        Text("Total Amount")
                            .font(.alphaBody)
                            .fontWeight(.semibold)
                        Spacer()
                        Text(totalAmount, format: .currency(code: "USD"))
                            .font(.alphaTitle)
                            .fontWeight(.bold)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Line Items")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .textCase(nil)
                }

                Section {
                    DatePicker("Date", selection: $expenseDate, displayedComponents: .date)
                } header: {
                    Text("Additional Details")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .textCase(nil)
                }
            }
            .navigationTitle("Quick Bill")
            .navigationBarTitleDisplayMode(.inline)
            .overlay {
                if isSubmitting {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()

                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Saving bill...")
                                .font(.alphaBody)
                                .foregroundColor(.alphaPrimaryText)
                        }
                        .padding(24)
                        .background(Color.alphaCardBackground)
                        .cornerRadius(12)
                        .shadow(radius: 10)
                    }
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await createBill()
                        }
                    }
                    .disabled(!isFormValid || isSubmitting)
                }
            }
            .task {
                await loadContacts()
            }
            .sheet(isPresented: $showingNewContact) {
                ContactFormSheet(isPresented: $showingNewContact, onSave: {
                    Task {
                        await loadContacts()
                    }
                })
            }
        }
    }

    private var isFormValid: Bool {
        guard selectedVendor != nil else { return false }
        guard !lineItems.isEmpty else { return false }

        // Check that at least one line item has a description and positive amount
        return lineItems.contains { !$0.description.isEmpty && $0.amount > 0 }
    }

    private func addLineItem() {
        lineItems.append(BillLineItem())
    }

    private func removeLineItem(_ item: BillLineItem) {
        lineItems.removeAll { $0.id == item.id }
    }

    private func loadContacts() async {
        isLoadingContacts = true

        do {
            contacts = try await apiClient.get("/clients?is_active=true")
        } catch {
            print("Failed to load contacts: \(error)")
            contacts = []
        }

        isLoadingContacts = false
    }

    private func createBill() async {
        isSubmitting = true
        errorMessage = nil

        do {
            let formatter = ISO8601DateFormatter()
            let dateString = formatter.string(from: expenseDate)

            let lineItemRequests = lineItems.map { item in
                ExpenseLineItemRequest(
                    description: item.description,
                    amount: item.amount,
                    category: item.category
                )
            }

            let request = CreateExpenseRequest(
                expenseDate: dateString,
                lineItems: lineItemRequests,
                currency: "USD"
            )

            let _: ExpenseResponse = try await apiClient.post("/expenses", body: request)

            isPresented = false
        } catch {
            errorMessage = "Failed to save bill: \(error.localizedDescription)"
        }

        isSubmitting = false
    }
}

// MARK: - Preview

#Preview("Quick Bill Sheet") {
    QuickBillSheet(isPresented: .constant(true))
}
