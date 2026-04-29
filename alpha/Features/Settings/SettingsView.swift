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
                        NavigationLink(destination: OrganizationSettingsSummaryView(organization: org)) {
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

                // Preferences Section
                Section("Preferences") {
                    NavigationLink(destination: NotificationPreferencesView(appState: appState)) {
                        Label("Notifications", systemImage: "bell")
                    }

                    NavigationLink(destination: DisplaySettingsView()) {
                        Label("Display", systemImage: "paintbrush")
                    }

                    NavigationLink(destination: TaxBillingDefaultsView(user: appState.currentUser)) {
                        Label("Tax & Billing Defaults", systemImage: "calendar.badge.clock")
                    }
                }

                // Business Section - Capability-based items
                if appState.hasCapability(.viewClients) {
                    Section("Business") {
                        NavigationLink(destination: ContactsListView()) {
                            Label("Contacts", systemImage: "person.2")
                        }
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
                    NavigationLink(destination: DataExportSettingsView(appState: appState)) {
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

private struct OrganizationSettingsSummaryView: View {
    let organization: Organization

    var body: some View {
        Form {
            Section("Business Information") {
                SettingsDetailRow(label: "Name", value: organization.name)
                SettingsDetailRow(label: "Email", value: organization.email)
                SettingsDetailRow(label: "Phone", value: organization.phone)
                SettingsDetailRow(label: "Tax ID / EIN", value: organization.taxId)
            }

            Section("Address") {
                SettingsDetailRow(label: "Street", value: organization.address)
                SettingsDetailRow(label: "City", value: organization.city)
                SettingsDetailRow(label: "State", value: organization.state)
                SettingsDetailRow(label: "ZIP / Postal Code", value: organization.zipCode)
                SettingsDetailRow(label: "Country", value: organization.country)
            }
        }
        .navigationTitle("Organization")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct TaxBillingDefaultsView: View {
    let user: User?

    private var preferences: [String: AnyCodable] {
        user?.preferences ?? [:]
    }

    var body: some View {
        Form {
            Section {
                SettingsDetailRow(label: "Default Tax Rate", value: formattedPreference("default_tax_rate", suffix: "%", fallback: "0%"))
                SettingsDetailRow(label: "Default Currency", value: stringPreference("default_currency") ?? "USD")
                SettingsDetailRow(label: "Fiscal Year Start", value: fiscalYearStart)
                SettingsDetailRow(label: "Payment Terms", value: paymentTerms)
                SettingsDetailRow(label: "Date Format", value: stringPreference("date_format") ?? "MM/DD/YYYY")
            } header: {
                Text("Tax & Billing Defaults")
            } footer: {
                Text("These defaults mirror the web app settings used when creating invoices, bills, and tax records.")
            }
        }
        .navigationTitle("Tax & Billing")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var fiscalYearStart: String {
        let monthNumber = intPreference("fiscal_year_start") ?? 1
        guard (1...12).contains(monthNumber) else { return "January" }
        return Calendar.current.monthSymbols[monthNumber - 1]
    }

    private var paymentTerms: String {
        let terms = intPreference("payment_terms") ?? 30
        return terms == 0 ? "Due on Receipt" : "Net \(terms)"
    }

    private func formattedPreference(_ key: String, suffix: String, fallback: String) -> String {
        if let double = doublePreference(key) {
            return String(format: "%.1f%@", double, suffix)
        }

        return fallback
    }

    private func stringPreference(_ key: String) -> String? {
        preferences[key]?.value as? String
    }

    private func intPreference(_ key: String) -> Int? {
        if let int = preferences[key]?.value as? Int {
            return int
        }

        if let double = preferences[key]?.value as? Double {
            return Int(double)
        }

        if let string = preferences[key]?.value as? String {
            return Int(string)
        }

        return nil
    }

    private func doublePreference(_ key: String) -> Double? {
        if let double = preferences[key]?.value as? Double {
            return double
        }

        if let int = preferences[key]?.value as? Int {
            return Double(int)
        }

        if let string = preferences[key]?.value as? String {
            return Double(string)
        }

        return nil
    }
}

private struct NotificationPreferencesView: View {
    let appState: AppState

    @AppStorage("notifications.overdue_invoices") private var overdueInvoices = true
    @AppStorage("notifications.bill_due_reminders") private var billDueReminders = true
    @AppStorage("notifications.payroll_confirmation") private var payrollConfirmation = true
    @AppStorage("notifications.low_stock_alerts") private var lowStockAlerts = false
    @AppStorage("notifications.weekly_summary") private var weeklySummary = false

    var body: some View {
        Form {
            Section {
                if appState.hasCapability(.viewInvoices) {
                    Toggle("Overdue Invoices", isOn: $overdueInvoices)
                }

                if appState.hasCapability(.viewBills) {
                    Toggle("Bill Due Reminders", isOn: $billDueReminders)
                }

                if appState.hasCapability(.viewPayroll) {
                    Toggle("Payroll Confirmation", isOn: $payrollConfirmation)
                }

                if appState.hasCapability(.viewInventory) {
                    Toggle("Low Stock Alerts", isOn: $lowStockAlerts)
                }

                Toggle("Weekly Summary", isOn: $weeklySummary)
            } header: {
                Text("Notification Preferences")
            } footer: {
                Text("Mobile notification toggles are stored on this device until server-backed notification preferences are enabled.")
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct DataExportSettingsView: View {
    let appState: AppState

    private var exportItems: [DataExportItem] {
        [
            DataExportItem(label: "Invoices", filename: "alpha-invoices.csv", capability: .viewInvoices),
            DataExportItem(label: "Invoice Line Items", filename: "alpha-invoice-lines.csv", capability: .viewInvoices),
            DataExportItem(label: "Expenses", filename: "alpha-expenses.csv", capability: .viewOwnExpenses),
            DataExportItem(label: "Bills", filename: "alpha-bills.csv", capability: .viewBills),
            DataExportItem(label: "Clients", filename: "alpha-clients.csv", capability: .viewClients),
            DataExportItem(label: "Projects", filename: "alpha-projects.csv", capability: .viewProjects),
            DataExportItem(label: "Time Entries", filename: "alpha-time-entries.csv", capability: .viewOwnTimeEntries),
            DataExportItem(label: "Tax Filings", filename: "alpha-tax-filings.csv", capability: .viewTaxDashboard)
        ].filter { appState.hasCapability($0.capability) }
    }

    var body: some View {
        Form {
            Section {
                ForEach(exportItems) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(item.label)
                            Spacer()
                            Text("CSV")
                                .font(.alphaCaption)
                                .foregroundColor(.alphaSecondaryText)
                        }

                        Text(item.filename)
                            .font(.alphaCaption)
                            .foregroundColor(.alphaSecondaryText)
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("CSV Exports")
            } footer: {
                Text("This matches the mobile V1 export surface from web Settings. File generation and sharing will be wired in a follow-up.")
            }
        }
        .navigationTitle("Export Data")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct DataExportItem: Identifiable {
    let id = UUID()
    let label: String
    let filename: String
    let capability: Capability
}

private struct SettingsDetailRow: View {
    let label: String
    let value: String?

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(displayValue)
                .foregroundColor(value == nil || value?.isEmpty == true ? .alphaTertiaryText : .alphaSecondaryText)
                .multilineTextAlignment(.trailing)
        }
    }

    private var displayValue: String {
        guard let value, !value.isEmpty else {
            return "Not set"
        }

        return value
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
