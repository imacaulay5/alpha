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
    @State private var lineItems: [LineItem] = [LineItem()]
    @State private var dueDate = Date()
    @State private var notes = ""
    @State private var showingNewContact = false
    @State private var showingTimeEntries = false
    @State private var selectedTimeEntries: [TimeEntry] = []
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private let clientRepository = ClientRepository()
    private let invoiceRepository = InvoiceRepository()
    private let timeEntryRepository = TimeEntryRepository()

    private var totalAmount: Double {
        let lineItemsTotal = lineItems.reduce(0) { $0 + $1.total }
        let timeEntriesTotal = selectedTimeEntries.reduce(0) { total, entry in
            if let amount = entry.billableAmount {
                return total + amount
            } else if let rate = entry.project?.rate {
                return total + (rate * entry.durationHours)
            }
            return total
        }
        return lineItemsTotal + timeEntriesTotal
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
                        Picker("Select Contact", selection: $selectedContact) {
                            Text("Select a contact").tag(nil as Contact?)
                            ForEach(contacts) { contact in
                                Text(contact.name).tag(contact as Contact?)
                            }
                        }

                        Button(action: { showingNewContact = true }) {
                            Label("Add New Contact", systemImage: "plus.circle.fill")
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
                } header: {
                    Text("Client Information")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .textCase(nil)
                }

                Section {
                    // Import from Time Entries Button
                    Button(action: { showingTimeEntries = true }) {
                        HStack {
                            Image(systemName: "clock.badge.checkmark")
                                .foregroundColor(.blue)
                            Text("Import from Time Entries")
                                .foregroundColor(.blue)
                            Spacer()
                            if !selectedTimeEntries.isEmpty {
                                Text("\(selectedTimeEntries.count) selected")
                                    .font(.alphaCaption)
                                    .foregroundColor(.secondary)
                            }
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)

                    // Selected Time Entries Summary
                    if !selectedTimeEntries.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(selectedTimeEntries, id: \.id) { entry in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(entry.project?.name ?? "Unknown Project")
                                            .font(.alphaBodySmall)
                                            .foregroundColor(.alphaPrimaryText)
                                        Text(entry.durationFormatted)
                                            .font(.alphaCaption)
                                            .foregroundColor(.alphaSecondaryText)
                                    }
                                    Spacer()
                                    if let amount = entry.billableAmount {
                                        Text(String(format: "$%.2f", amount))
                                            .font(.alphaBodySmall)
                                            .fontWeight(.medium)
                                            .foregroundColor(.alphaSuccess)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Time Entries")
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
                                    Text("Quantity")
                                        .font(.alphaCaption)
                                        .foregroundColor(.alphaSecondaryText)
                                    TextField("0", value: $item.quantity, format: .number)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(.roundedBorder)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Rate")
                                        .font(.alphaCaption)
                                        .foregroundColor(.alphaSecondaryText)
                                    TextField("0.00", value: $item.rate, format: .currency(code: "USD"))
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(.roundedBorder)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Total")
                                        .font(.alphaCaption)
                                        .foregroundColor(.alphaSecondaryText)
                                    Text(item.total, format: .currency(code: "USD"))
                                        .font(.alphaBody)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.alphaPrimary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.top, 6)
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
                    Text("Additional Line Items")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .textCase(nil)
                }

                Section {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)

                    TextField("Notes", text: $notes, prompt: Text("Optional"), axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Additional Details")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .textCase(nil)
                }
            }
            .navigationTitle("Create Invoice")
            .navigationBarTitleDisplayMode(.inline)
            .overlay {
                if isSubmitting {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()

                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Creating invoice...")
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
                    Button("Create") {
                        Task {
                            await createInvoice()
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
            .sheet(isPresented: $showingTimeEntries) {
                SelectTimeEntriesSheet(isPresented: $showingTimeEntries) { entries in
                    selectedTimeEntries = entries
                }
            }
        }
    }

    private var isFormValid: Bool {
        guard selectedContact != nil else { return false }

        // Need either time entries or at least one valid line item
        let hasTimeEntries = !selectedTimeEntries.isEmpty
        let hasValidLineItem = lineItems.contains { !$0.description.isEmpty && $0.rate > 0 }

        return hasTimeEntries || hasValidLineItem
    }

    private func addLineItem() {
        lineItems.append(LineItem())
    }

    private func removeLineItem(_ item: LineItem) {
        lineItems.removeAll { $0.id == item.id }
    }

    private func loadContacts() async {
        isLoadingContacts = true

        do {
            contacts = try await clientRepository.fetchClients()
        } catch {
            print("Failed to load contacts: \(error)")
            contacts = []
        }

        isLoadingContacts = false
    }

    private func createInvoice() async {
        guard let contact = selectedContact else { return }

        isSubmitting = true
        errorMessage = nil

        do {
            // Convert time entries to line items
            var allLineItems: [InvoiceLineItemCreate] = []

            // Group time entries by project for cleaner invoices
            let entriesByProject = Dictionary(grouping: selectedTimeEntries) { $0.projectId }
            for (_, entries) in entriesByProject {
                let projectName = entries.first?.project?.name ?? "Time Entry"
                let totalHours = entries.reduce(0) { $0 + $1.durationHours }
                let rate = entries.first?.billableRate ?? entries.first?.project?.rate ?? 0

                if totalHours > 0 {
                    allLineItems.append(InvoiceLineItemCreate(
                        description: "\(projectName) - \(String(format: "%.1f", totalHours)) hours",
                        quantity: totalHours,
                        rate: rate
                    ))
                }
            }

            // Add manual line items
            for item in lineItems where !item.description.isEmpty && item.rate > 0 {
                allLineItems.append(InvoiceLineItemCreate(
                    description: item.description,
                    quantity: item.quantity,
                    rate: item.rate
                ))
            }

            let invoice = try await invoiceRepository.createInvoice(
                clientId: contact.id,
                projectId: nil,
                dueDate: dueDate,
                lineItems: allLineItems,
                taxRate: nil,
                notes: notes.isEmpty ? nil : notes,
                currency: "USD"
            )

            // Mark time entries as invoiced
            if !selectedTimeEntries.isEmpty {
                let entryIds = selectedTimeEntries.map { $0.id }
                try await timeEntryRepository.markAsInvoiced(ids: entryIds, invoiceId: invoice.id)
            }

            isPresented = false
        } catch {
            errorMessage = "Failed to create invoice: \(error.localizedDescription)"
        }

        isSubmitting = false
    }
}

// MARK: - Preview

#Preview("Create Invoice Sheet") {
    CreateInvoiceSheet(isPresented: .constant(true))
}
