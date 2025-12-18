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
    @State private var amount = ""
    @State private var description = ""
    @State private var category = "OFFICE_SUPPLIES"
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
