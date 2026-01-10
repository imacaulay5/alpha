//
//  Role.swift
//  alpha
//
//  Created by Claude Code on 11/25/25.
//

import Foundation

enum Role: String, Codable {
    case owner = "OWNER"
    case admin = "ADMIN"
    case member = "MEMBER"
    case contractor = "CONTRACTOR"

    var displayName: String {
        switch self {
        case .owner:
            return "Owner"
        case .admin:
            return "Admin"
        case .member:
            return "Member"
        case .contractor:
            return "Contractor"
        }
    }

    // MARK: - Deprecated Permission Methods
    // Use capability system instead

    @available(*, deprecated, message: "Use hasCapability(.manageUsers) instead")
    var canManageUsers: Bool {
        switch self {
        case .owner, .admin:
            return true
        case .member, .contractor:
            return false
        }
    }

    @available(*, deprecated, message: "Use hasCapability(.approveExpenses) instead")
    var canApproveExpenses: Bool {
        switch self {
        case .owner, .admin:
            return true
        case .member, .contractor:
            return false
        }
    }
}

// MARK: - Role-Based Capabilities

extension Role {
    /// Additional capabilities granted to this role within a business account
    /// For non-business accounts, the account type determines capabilities
    var additionalCapabilities: Set<Capability> {
        switch self {
        case .owner:
            // Owner has all capabilities (already granted by business account type)
            return Set(Capability.allCases)

        case .admin:
            // Admins can do everything except delete org or manage organization settings
            return Set(Capability.allCases).subtracting([
                .deleteAccount,
                .manageOrganization
            ])

        case .member:
            // Regular team members have limited access
            return [
                // Time tracking
                .trackTime,
                .viewOwnTimeEntries,
                .editOwnTimeEntries,

                // Expenses
                .submitExpenses,
                .viewOwnExpenses,
                .categorizeExpenses,
                .attachReceipts,
                .trackMileage,

                // Projects (view only)
                .viewProjects,
                .viewTasks,

                // Basic viewing
                .viewClients,
                .viewBasicReports,

                // Settings
                .configureNotifications,
                .customizeAppearance
            ]

        case .contractor:
            // External contractors
            return [
                // Time tracking
                .trackTime,
                .viewOwnTimeEntries,
                .editOwnTimeEntries,

                // Invoicing (for their work)
                .createInvoices,
                .sendInvoices,
                .viewInvoices,

                // Projects assigned to them
                .viewProjects,
                .viewTasks,

                // Expenses
                .submitExpenses,
                .viewOwnExpenses,
                .attachReceipts,

                // Settings
                .configureNotifications,
                .customizeAppearance
            ]
        }
    }
}
