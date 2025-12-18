//
//  Contact.swift
//  alpha
//
//  Created by Claude Code on 12/17/25.
//

import Foundation

struct Contact: Codable, Identifiable, Hashable {
    let id: String
    let organizationId: String
    var name: String
    var email: String?
    var phone: String?
    var address: String?
    var city: String?
    var state: String?
    var zipCode: String?
    var country: String?
    var contactName: String?
    var notes: String?
    var isActive: Bool
    let createdAt: Date
    let updatedAt: Date

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

    var displayName: String {
        name
    }

    var fullAddress: String {
        var components: [String] = []

        if let address = address, !address.isEmpty {
            components.append(address)
        }
        if let city = city, !city.isEmpty {
            components.append(city)
        }
        if let state = state, !state.isEmpty {
            components.append(state)
        }
        if let zipCode = zipCode, !zipCode.isEmpty {
            components.append(zipCode)
        }

        return components.joined(separator: ", ")
    }
}

// MARK: - Create/Update DTOs

struct ContactCreate: Codable {
    var name: String
    var email: String?
    var phone: String?
    var address: String?
    var city: String?
    var state: String?
    var zipCode: String?
    var country: String?
    var contactName: String?
    var notes: String?
    var isActive: Bool = true

    enum CodingKeys: String, CodingKey {
        case name, email, phone, address, city, state, country, notes
        case zipCode = "zip_code"
        case contactName = "contact_name"
        case isActive = "is_active"
    }
}

// MARK: - Preview Data

extension Contact {
    static let preview = Contact(
        id: "preview-1",
        organizationId: "org-1",
        name: "Acme Corporation",
        email: "contact@acme.com",
        phone: "+1 555-0100",
        address: "123 Main St",
        city: "San Francisco",
        state: "CA",
        zipCode: "94102",
        country: "USA",
        contactName: "John Smith",
        notes: "Primary client",
        isActive: true,
        createdAt: Date(),
        updatedAt: Date()
    )

    static let previewList: [Contact] = [
        Contact(
            id: "1",
            organizationId: "org-1",
            name: "Acme Corporation",
            email: "contact@acme.com",
            phone: "+1 555-0100",
            address: "123 Main St",
            city: "San Francisco",
            state: "CA",
            zipCode: "94102",
            country: "USA",
            contactName: "John Smith",
            notes: nil,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        ),
        Contact(
            id: "2",
            organizationId: "org-1",
            name: "TechCorp Inc",
            email: "info@techcorp.com",
            phone: "+1 555-0200",
            address: "456 Tech Blvd",
            city: "Austin",
            state: "TX",
            zipCode: "78701",
            country: "USA",
            contactName: "Jane Doe",
            notes: nil,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        ),
        Contact(
            id: "3",
            organizationId: "org-1",
            name: "Global Industries",
            email: "hello@global.com",
            phone: "+1 555-0300",
            address: nil,
            city: "New York",
            state: "NY",
            zipCode: "10001",
            country: "USA",
            contactName: nil,
            notes: "Vendor for office supplies",
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )
    ]
}
