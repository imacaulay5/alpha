//
//  AccountType.swift
//  alpha
//
//  Created by Claude Code on 12/29/24.
//

import Foundation

enum AccountType: String, Codable, CaseIterable {
    case personal
    case freelancer
    case business

    var displayName: String {
        switch self {
        case .personal:
            return "Personal"
        case .freelancer:
            return "Freelancer/Contractor"
        case .business:
            return "Small Business Owner"
        }
    }

    var description: String {
        switch self {
        case .personal:
            return "Track your time and finances"
        case .freelancer:
            return "Manage clients and invoices"
        case .business:
            return "Track team time and projects"
        }
    }

    var icon: String {
        switch self {
        case .personal:
            return "person.fill"
        case .freelancer:
            return "briefcase.fill"
        case .business:
            return "building.2.fill"
        }
    }

    var requiresOrganization: Bool {
        self == .business
    }

    var defaultRole: String {
        switch self {
        case .personal:
            return "MEMBER"
        case .freelancer:
            return "CONTRACTOR"
        case .business:
            return "OWNER"
        }
    }
}

// MARK: - Capability Mapping

extension AccountType {
    /// Returns the set of capabilities available to this account type
    var capabilities: Set<Capability> {
        switch self {
        case .personal:
            return [
                // Time & Basic Tracking
                .trackTime,
                .viewOwnTimeEntries,
                .editOwnTimeEntries,

                // Basic Invoicing (for side work)
                .createInvoices,
                .sendInvoices,
                .viewInvoices,
                .editInvoices,
                .recordPayments,

                // Personal Expenses
                .submitExpenses,
                .viewOwnExpenses,
                .categorizeExpenses,
                .attachReceipts,

                // Simple Reports
                .viewBasicReports,
                .exportData,

                // Tax Basics
                .viewTaxDashboard,
                .exportTaxDocuments,

                // Settings
                .configureNotifications,
                .customizeAppearance,
                .exportAllData,
                .deleteAccount
            ]

        case .freelancer:
            return [
                // Time Tracking (enhanced)
                .trackTime,
                .viewOwnTimeEntries,
                .editOwnTimeEntries,
                .deleteTimeEntries,

                // Professional Invoicing
                .createInvoices,
                .sendInvoices,
                .viewInvoices,
                .editInvoices,
                .deleteInvoices,
                .customizeInvoiceTemplate,
                .schedulePaymentReminders,
                .recordPayments,
                .processRefunds,
                .quickBill,
                .viewAccountsReceivable,

                // Client Management
                .manageClients,
                .viewClients,
                .importContacts,
                .exportContacts,

                // Project Management
                .createProjects,
                .manageProjects,
                .viewProjects,
                .viewTasks,
                .configureBillingRules,
                .trackProjectBudgets,
                .viewProjectReports,

                // Expense Management
                .submitExpenses,
                .viewOwnExpenses,
                .categorizeExpenses,
                .attachReceipts,
                .trackMileage,

                // Advanced Reports
                .viewAdvancedReports,
                .viewFinancialStatements,
                .exportData,
                .customizeReports,

                // Tax & Compliance
                .viewTaxDashboard,
                .generateTaxEstimates,
                .exportTaxDocuments,

                // Integrations
                .connectBankAccounts,
                .connectPaymentProcessors,

                // Settings
                .configureNotifications,
                .customizeAppearance,
                .exportAllData,
                .deleteAccount
            ]

        case .business:
            // Business gets ALL capabilities by default
            return Set(Capability.allCases)
        }
    }

    /// Check if this account type has a specific capability
    func hasCapability(_ capability: Capability) -> Bool {
        capabilities.contains(capability)
    }
}
