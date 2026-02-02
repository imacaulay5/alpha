//
//  ContactFormSheet.swift
//  alpha
//
//  Created by Claude Code on 12/17/25.
//

import SwiftUI

struct ContactFormSheet: View {
    @Binding var isPresented: Bool
    var contact: Contact?
    var onSave: () -> Void

    @State private var name: String
    @State private var email: String
    @State private var phone: String
    @State private var address: String
    @State private var city: String
    @State private var state: String
    @State private var zipCode: String
    @State private var country: String
    @State private var contactName: String
    @State private var notes: String

    @State private var isSaving = false
    @State private var errorMessage: String?

    private let clientRepository = ClientRepository()

    init(isPresented: Binding<Bool>, contact: Contact? = nil, onSave: @escaping () -> Void) {
        self._isPresented = isPresented
        self.contact = contact
        self.onSave = onSave

        // Initialize state from contact if editing
        _name = State(initialValue: contact?.name ?? "")
        _email = State(initialValue: contact?.email ?? "")
        _phone = State(initialValue: contact?.phone ?? "")
        _address = State(initialValue: contact?.address ?? "")
        _city = State(initialValue: contact?.city ?? "")
        _state = State(initialValue: contact?.state ?? "")
        _zipCode = State(initialValue: contact?.zipCode ?? "")
        _country = State(initialValue: contact?.country ?? "")
        _contactName = State(initialValue: contact?.contactName ?? "")
        _notes = State(initialValue: contact?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Company Information") {
                    TextField("Company Name", text: $name)

                    TextField("Contact Person", text: $contactName)
                }

                Section("Contact Details") {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)

                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                }

                Section("Address") {
                    TextField("Street Address", text: $address)

                    TextField("City", text: $city)

                    HStack {
                        TextField("State", text: $state)

                        TextField("ZIP Code", text: $zipCode)
                            .keyboardType(.numbersAndPunctuation)
                    }

                    TextField("Country", text: $country)
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .font(.alphaBodySmall)
                            .foregroundColor(.alphaError)
                    }
                }
            }
            .navigationTitle(contact == nil ? "New Contact" : "Edit Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(contact == nil ? "Add" : "Save") {
                        Task {
                            await saveContact()
                        }
                    }
                    .disabled(name.isEmpty || isSaving)
                }
            }
            .overlay {
                if isSaving {
                    ProgressView()
                }
            }
        }
    }

    private func saveContact() async {
        isSaving = true
        errorMessage = nil

        do {
            if let existingContact = contact {
                // Update existing contact
                _ = try await clientRepository.updateClient(
                    id: existingContact.id,
                    name: name,
                    email: email.isEmpty ? nil : email,
                    phone: phone.isEmpty ? nil : phone,
                    address: address.isEmpty ? nil : address,
                    city: city.isEmpty ? nil : city,
                    state: state.isEmpty ? nil : state,
                    zipCode: zipCode.isEmpty ? nil : zipCode,
                    country: country.isEmpty ? nil : country,
                    contactName: contactName.isEmpty ? nil : contactName,
                    notes: notes.isEmpty ? nil : notes
                )
            } else {
                // Create new contact
                _ = try await clientRepository.createClient(
                    name: name,
                    email: email.isEmpty ? nil : email,
                    phone: phone.isEmpty ? nil : phone,
                    address: address.isEmpty ? nil : address,
                    city: city.isEmpty ? nil : city,
                    state: state.isEmpty ? nil : state,
                    zipCode: zipCode.isEmpty ? nil : zipCode,
                    country: country.isEmpty ? nil : country,
                    contactName: contactName.isEmpty ? nil : contactName,
                    notes: notes.isEmpty ? nil : notes
                )
            }

            onSave()
            isPresented = false
        } catch {
            errorMessage = "Failed to save contact: \(error.localizedDescription)"
        }

        isSaving = false
    }
}

// MARK: - Preview

#Preview("New Contact") {
    ContactFormSheet(isPresented: .constant(true), onSave: {})
}

#Preview("Edit Contact") {
    ContactFormSheet(isPresented: .constant(true), contact: .preview, onSave: {})
}
