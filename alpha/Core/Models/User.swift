//
//  User.swift
//  alpha
//
//  Created by Claude Code on 11/25/25.
//

import Foundation

struct User: Codable, Identifiable {
    let id: String
    let organizationId: String
    let email: String
    let name: String
    let role: Role
    let hourlyRate: Double?
    let isActive: Bool
    let avatarUrl: String?
    let phone: String?
    let timezone: String?
    let preferences: [String: AnyCodable]?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case organizationId = "organization_id"
        case email
        case name
        case role
        case hourlyRate = "hourly_rate"
        case isActive = "is_active"
        case avatarUrl = "avatar_url"
        case phone
        case timezone
        case preferences
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // Computed properties
    var initials: String {
        let components = name.components(separatedBy: " ")
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let last = components[1].prefix(1)
            return "\(first)\(last)".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    var isAdmin: Bool {
        role == .owner || role == .admin
    }
}

// MARK: - Preview Helpers
extension User {
    static let preview = User(
        id: "user_1",
        organizationId: "org_1",
        email: "john@example.com",
        name: "John Doe",
        role: .member,
        hourlyRate: 150.0,
        isActive: true,
        avatarUrl: nil,
        phone: "+1 555-0123",
        timezone: "America/Los_Angeles",
        preferences: nil,
        createdAt: Date(),
        updatedAt: Date()
    )
}
