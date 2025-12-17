//
//  Client.swift
//  alpha
//
//  Created by Claude Code on 11/25/25.
//

import Foundation

struct Client: Codable, Identifiable, Hashable {
    let id: String
    let organizationId: String?
    let name: String
    let email: String?
    let phone: String?
    let address: String?
    let city: String?
    let state: String?
    let zipCode: String?
    let country: String?
    let contactName: String?
    let notes: String?
    let isActive: Bool?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case organizationId = "organization_id"
        case name
        case email
        case phone
        case address
        case city
        case state
        case zipCode = "zip_code"
        case country
        case contactName = "contact_name"
        case notes
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Preview Helpers
extension Client {
    static let preview = Client(
        id: "client_1",
        organizationId: "org_1",
        name: "Tech Startup Inc",
        email: "contact@techstartup.com",
        phone: "+1 555-0200",
        address: "456 Innovation Dr",
        city: "Palo Alto",
        state: "CA",
        zipCode: "94301",
        country: "USA",
        contactName: "Jane Smith",
        notes: "Great client, always pays on time",
        isActive: true,
        createdAt: Date(),
        updatedAt: Date()
    )

    static let previewMinimal = Client(
        id: "client_1",
        organizationId: nil,
        name: "Tech Startup Inc",
        email: nil,
        phone: nil,
        address: nil,
        city: nil,
        state: nil,
        zipCode: nil,
        country: nil,
        contactName: nil,
        notes: nil,
        isActive: nil,
        createdAt: nil,
        updatedAt: nil
    )
}
