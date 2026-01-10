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
