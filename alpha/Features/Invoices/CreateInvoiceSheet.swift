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
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private let apiClient = APIClient.shared

    // Request structure matching backend schema
    private struct CreateInvoiceRequest: Codable {
        let clientId: String
        let dueDate: String
        let lineItems: [InvoiceLineItemRequest]
        let notes: String?
        let currency: String

        enum CodingKeys: String, CodingKey {
            case clientId = "client_id"
            case dueDate = "due_date"
            case lineItems = "line_items"
            case notes
            case currency
        }
    }

    private struct InvoiceLineItemRequest: Codable {
        let description: String
        let quantity: Double
        let rate: Double
    }

    private struct InvoiceResponse: Codable {
        let id: String
        let invoiceNumber: String

        enum CodingKeys: String, CodingKey {
            case id
            case invoiceNumber = "invoice_number"
        }
    }

    private var totalAmount: Double {
        lineItems.reduce(0) { $0 + $1.total }
    }

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

                Section("Line Items") {
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
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)

                    TextField("Notes (Optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
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
        }
    }

    private var isFormValid: Bool {
        guard selectedContact != nil else { return false }
        guard !lineItems.isEmpty else { return false }

        // Check that at least one line item has a description and positive rate
        return lineItems.contains { !$0.description.isEmpty && $0.rate > 0 }
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
            contacts = try await apiClient.get("/clients?is_active=true")
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
            let formatter = ISO8601DateFormatter()
            let dueDateString = formatter.string(from: dueDate)

            let lineItemRequests = lineItems.map { item in
                InvoiceLineItemRequest(
                    description: item.description,
                    quantity: item.quantity,
                    rate: item.rate
                )
            }

            let request = CreateInvoiceRequest(
                clientId: contact.id,
                dueDate: dueDateString,
                lineItems: lineItemRequests,
                notes: notes.isEmpty ? nil : notes,
                currency: "USD"
            )

            let _: InvoiceResponse = try await apiClient.post("/invoices", body: request)

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
