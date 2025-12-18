//
//  CreateInvoiceSheet.swift
//  alpha
//
//  Created by Claude Code on 12/17/25.
//

import SwiftUI

struct CreateInvoiceSheet: View {
    @Binding var isPresented: Bool
    @State private var selectedContact: Contact?
    @State private var contacts: [Contact] = []
    @State private var isLoadingContacts = false
    @State private var amount = ""
    @State private var dueDate = Date()
    @State private var notes = ""
    @State private var showingNewContact = false

    private let apiClient = APIClient.shared

    var body: some View {
        NavigationStack {
            Form {
                Section("Client Information") {
                    if isLoadingContacts {
                        HStack {
                            ProgressView()
                            Text("Loading contacts...")
                                .foregroundColor(.alphaSecondaryText)
                        }
                    } else {
                        Picker("Select Contact", selection: $selectedContact) {
                            Text("Select a contact").tag(nil as Contact?)
                            ForEach(contacts) { contact in
                                Text(contact.name).tag(contact as Contact?)
                            }
                        }

                        Button(action: { showingNewContact = true }) {
                            Label("Add New Contact", systemImage: "plus.circle.fill")
                                .foregroundColor(.alphaPrimary)
                        }

                        if let contact = selectedContact {
                            VStack(alignment: .leading, spacing: 8) {
                                if let email = contact.email {
                                    Label(email, systemImage: "envelope")
                                        .font(.alphaBodySmall)
                                        .foregroundColor(.alphaSecondaryText)
                                }
                                if let phone = contact.phone {
                                    Label(phone, systemImage: "phone")
                                        .font(.alphaBodySmall)
                                        .foregroundColor(.alphaSecondaryText)
                                }
                            }
                        }
                    }
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
                    .disabled(selectedContact == nil || amount.isEmpty)
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

#Preview("Create Invoice Sheet") {
    CreateInvoiceSheet(isPresented: .constant(true))
}
