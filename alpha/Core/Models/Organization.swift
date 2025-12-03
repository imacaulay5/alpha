//
//  Organization.swift
//  alpha
//
//  Created by Claude Code on 11/25/25.
//

import Foundation

struct Organization: Codable, Identifiable {
    let id: String
    let name: String
    let email: String?
    let phone: String?
    let address: String?
    let city: String?
    let state: String?
    let zipCode: String?
    let country: String?
    let taxId: String?
    let settings: [String: AnyCodable]?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case phone
        case address
        case city
        case state
        case zipCode = "zip_code"
        case country
        case taxId = "tax_id"
        case settings
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Preview Helpers
extension Organization {
    static let preview = Organization(
        id: "org_1",
        name: "Acme Corporation",
        email: "contact@acme.com",
        phone: "+1 555-0100",
        address: "123 Main St",
        city: "San Francisco",
        state: "CA",
        zipCode: "94102",
        country: "USA",
        taxId: "12-3456789",
        settings: nil,
        createdAt: Date(),
        updatedAt: Date()
    )
}
