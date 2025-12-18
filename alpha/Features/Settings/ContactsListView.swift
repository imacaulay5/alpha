//
//  ContactsListView.swift
//  alpha
//
//  Created by Claude Code on 12/17/25.
//

import SwiftUI
import Combine

// MARK: - ViewModel

@MainActor
class ContactsViewModel: ObservableObject {
    @Published var contacts: [Contact] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiClient = APIClient.shared

    // MARK: - Public Methods

    func loadContacts() async {
        isLoading = true
        errorMessage = nil

        do {
            contacts = try await apiClient.get("/clients?is_active=true")
        } catch {
            errorMessage = "Failed to load contacts: \(error.localizedDescription)"
            contacts = []
        }

        isLoading = false
    }

    func deleteContact(_ contactId: String) async {
        do {
            let _: [String: String] = try await apiClient.delete("/clients/\(contactId)")
            await loadContacts()
        } catch {
            errorMessage = "Failed to delete contact: \(error.localizedDescription)"
        }
    }
}

// MARK: - ContactsListView

struct ContactsListView: View {
    @StateObject private var viewModel = ContactsViewModel()
    @State private var showingAddContact = false
    @State private var selectedContact: Contact?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.isLoading {
                        ProgressView()
                            .padding(.top, 40)
                    } else if viewModel.contacts.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.contacts) { contact in
                                ContactRow(contact: contact)
                                    .onTapGesture {
                                        selectedContact = contact
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            Task {
                                                await viewModel.deleteContact(contact.id)
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color.alphaGroupedBackground)
            .navigationTitle("Contacts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddContact = true }) {
                        Image(systemName: "plus")
                            .foregroundColor(.alphaPrimary)
                    }
                }
            }
            .refreshable {
                await viewModel.loadContacts()
            }
            .task {
                await viewModel.loadContacts()
            }
            .sheet(isPresented: $showingAddContact) {
                ContactFormSheet(isPresented: $showingAddContact, onSave: {
                    Task {
                        await viewModel.loadContacts()
                    }
                })
            }
            .sheet(item: $selectedContact) { contact in
                ContactFormSheet(isPresented: .constant(true), contact: contact, onSave: {
                    Task {
                        await viewModel.loadContacts()
                        selectedContact = nil
                    }
                })
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2")
                .font(.system(size: 48))
                .foregroundColor(.alphaSecondaryText)

            Text("No contacts yet")
                .font(.alphaBody)
                .foregroundColor(.alphaSecondaryText)

            Text("Tap + to add your first contact")
                .font(.alphaBodySmall)
                .foregroundColor(.alphaTertiaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

// MARK: - Contact Row

struct ContactRow: View {
    let contact: Contact

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Initials circle
                Circle()
                    .fill(Color.alphaPrimary.opacity(0.2))
                    .frame(width: 48, height: 48)
                    .overlay {
                        Text(initials)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.alphaPrimary)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.alphaPrimaryText)

                    if let contactName = contact.contactName {
                        Text(contactName)
                            .font(.system(size: 14))
                            .foregroundColor(.alphaSecondaryText)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.alphaSecondaryText)
            }

            if contact.email != nil || contact.phone != nil {
                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    if let email = contact.email {
                        HStack(spacing: 8) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.alphaSecondaryText)
                                .frame(width: 16)

                            Text(email)
                                .font(.system(size: 13))
                                .foregroundColor(.alphaSecondaryText)
                        }
                    }

                    if let phone = contact.phone {
                        HStack(spacing: 8) {
                            Image(systemName: "phone.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.alphaSecondaryText)
                                .frame(width: 16)

                            Text(phone)
                                .font(.system(size: 13))
                                .foregroundColor(.alphaSecondaryText)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.alphaCardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var initials: String {
        let components = contact.name.split(separator: " ")
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let last = components[1].prefix(1)
            return "\(first)\(last)".uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return "?"
    }
}

// MARK: - Preview

#Preview("Contacts List") {
    ContactsListView()
}

#Preview("Contact Row") {
    ContactRow(contact: .preview)
        .padding()
}
