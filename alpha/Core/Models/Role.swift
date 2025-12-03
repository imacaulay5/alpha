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

    var canManageUsers: Bool {
        switch self {
        case .owner, .admin:
            return true
        case .member, .contractor:
            return false
        }
    }

    var canApproveExpenses: Bool {
        switch self {
        case .owner, .admin:
            return true
        case .member, .contractor:
            return false
        }
    }
}
