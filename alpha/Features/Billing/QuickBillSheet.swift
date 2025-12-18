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

    private let apiClient = APIClient.shared

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
                Section("Vendor Information") {
                    if isLoadingContacts {
                        HStack {
                            ProgressView()
                            Text("Loading contacts...")
                                .foregroundColor(.alphaSecondaryText)
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
                                .foregroundColor(.alphaPrimary)
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
                }

                Section("Line Items") {
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
                                    .tint(.alphaPrimary)
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
                            .foregroundColor(.alphaPrimary)
                    }

                    HStack {
                        Text("Total Amount")
                            .font(.alphaBody)
                            .fontWeight(.semibold)
                        Spacer()
                        Text(totalAmount, format: .currency(code: "USD"))
                            .font(.alphaTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.alphaPrimary)
                    }
                    .padding(.vertical, 8)
                }

                Section("Additional Details") {
                    DatePicker("Date", selection: $expenseDate, displayedComponents: .date)
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
                    .disabled(!isFormValid)
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
}

// MARK: - Preview

#Preview("Quick Bill Sheet") {
    QuickBillSheet(isPresented: .constant(true))
}
