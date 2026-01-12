//
//  SettingsView.swift
//  alpha
//
//  Created by Claude Code on 11/25/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingSignOutConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                // User Profile Section
                Section {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Color.alphaPrimary)
                            .frame(width: 60, height: 60)
                            .overlay {
                                Text(appState.currentUser?.initials ?? "")
                                    .font(.title)
                                    .foregroundColor(.white)
                            }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(appState.currentUser?.name ?? "User")
                                .font(.alphaHeadline)
                                .foregroundColor(.alphaPrimaryText)

                            Text(appState.currentUser?.email ?? "")
                                .font(.alphaBodySmall)
                                .foregroundColor(.alphaSecondaryText)

                            Text(appState.currentUser?.role.displayName ?? "")
                                .font(.alphaLabel)
                                .foregroundColor(.alphaTertiaryText)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Organization Section - Business accounts only
                if let org = appState.organization,
                   appState.hasCapability(.manageOrganization) {
                    Section("Organization") {
                        NavigationLink(destination: Text("Organization Settings")) {
                            Label("Organization Settings", systemImage: "building.2")
                        }

                        HStack {
                            Text("Company")
                            Spacer()
                            Text(org.name)
                                .foregroundColor(.alphaSecondaryText)
                        }

                        if let email = org.email {
                            HStack {
                                Text("Email")
                                Spacer()
                                Text(email)
                                    .foregroundColor(.alphaSecondaryText)
                            }
                        }
                    }
                }

                // Team Section - For users who can manage team
                if appState.currentUser?.canManageTeam == true {
                    Section("Team") {
                        NavigationLink(destination: Text("Team Members")) {
                            Label("Team Members", systemImage: "person.3")
                        }
                        .requiresCapability(.manageUsers)

                        NavigationLink(destination: Text("Invite Users")) {
                            Label("Invite Users", systemImage: "person.badge.plus")
                        }
                        .requiresCapability(.inviteTeamMembers)

                        NavigationLink(destination: Text("Audit Log")) {
                            Label("Audit Log", systemImage: "list.clipboard")
                        }
                        .requiresCapability(.viewAuditLog)
                    }
                }

                // Preferences Section
                Section("Preferences") {
                    NavigationLink(destination: Text("Notifications")) {
                        Label("Notifications", systemImage: "bell")
                    }

                    NavigationLink(destination: DisplaySettingsView()) {
                        Label("Display", systemImage: "paintbrush")
                    }

                    NavigationLink(destination: Text("Date & Time")) {
                        Label("Date & Time", systemImage: "calendar")
                    }
                }

                // Business Section - Capability-based items
                if appState.hasCapability(.viewClients) ||
                   appState.hasCapability(.configureBillingRules) {
                    Section("Business") {
                        if appState.hasCapability(.viewClients) {
                            NavigationLink(destination: ContactsListView()) {
                                Label("Contacts", systemImage: "person.2")
                            }
                        }

                        NavigationLink(destination: BillingRulesView()) {
                            Label("Billing Rules", systemImage: "chart.bar.doc.horizontal")
                        }
                        .requiresCapability(.configureBillingRules)
                    }
                }

                // Tax & Compliance - Freelancer+ only
                if appState.hasCapability(.viewTaxDashboard) &&
                   appState.currentUser?.accountType == .freelancer {
                    Section("Tax & Compliance") {
                        NavigationLink(destination: TaxComplianceView()) {
                            Label("Tax Dashboard", systemImage: "doc.plaintext.fill")
                        }

                        NavigationLink(destination: Text("Tax Estimates")) {
                            Label("Tax Estimates", systemImage: "calculator")
                        }
                        .requiresCapability(.generateTaxEstimates)

                        NavigationLink(destination: Text("Tax Documents")) {
                            Label("Tax Documents", systemImage: "folder.fill")
                        }
                        .requiresCapability(.exportTaxDocuments)
                    }
                }

                // Integrations Section - Advanced users
                if appState.hasCapability(.manageIntegrations) {
                    Section("Integrations") {
                        NavigationLink(destination: Text("Connected Accounts")) {
                            Label("Connected Accounts", systemImage: "link")
                        }

                        NavigationLink(destination: Text("API Settings")) {
                            Label("API Settings", systemImage: "chevron.left.forwardslash.chevron.right")
                        }
                    }
                }

                // Data Section
                Section("Data") {
                    NavigationLink(destination: Text("Export Data")) {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }
                    .requiresCapability(.exportAllData)

                    NavigationLink(destination: Text("Offline Data")) {
                        Label("Offline Data", systemImage: "arrow.down.circle")
                    }
                }

                // Support Section
                Section("Support") {
                    NavigationLink(destination: Text("Help Center")) {
                        Label("Help Center", systemImage: "questionmark.circle")
                    }

                    NavigationLink(destination: Text("Send Feedback")) {
                        Label("Send Feedback", systemImage: "envelope")
                    }

                    NavigationLink(destination: Text("About")) {
                        Label("About", systemImage: "info.circle")
                    }
                }

                // Sign Out Section
                Section {
                    Button(role: .destructive) {
                        showingSignOutConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .font(.alphaBody)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog(
                "Are you sure you want to sign out?",
                isPresented: $showingSignOutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) {
                    Task {
                        try? await AuthService.shared.logout()
                        appState.logout()
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

// MARK: - Preview

#Preview("Settings") {
    SettingsView()
        .environmentObject({
            let state = AppState()
            state.isAuthenticated = true
            state.currentUser = .preview
            state.organization = .preview
            return state
        }())
}
