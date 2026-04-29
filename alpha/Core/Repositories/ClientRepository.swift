//
//  ClientRepository.swift
//  alpha
//
//  Created by Claude Code on 2/1/26.
//

import Foundation
import Supabase

class ClientRepository {
    private let supabase = SupabaseClientManager.shared.client
    private let ownershipResolver = OwnershipResolver()

    func fetchClients(activeOnly: Bool = true) async throws -> [Contact] {
        let scope = try await ownershipResolver.currentScope()
        var query = supabase
            .from("clients")
            .select("*")

        if let organizationId = scope.organizationId {
            query = query.eq("organization_id", value: organizationId)
        } else {
            query = query.eq("user_id", value: scope.userId)
        }

        if activeOnly {
            query = query.eq("is_active", value: true)
        }

        let response = try await query
            .order("name")
            .execute()

        let clients: [Contact] = try JSONDecoder().decode([Contact].self, from: response.data)
        return clients
    }

    func fetchClient(id: String) async throws -> Contact {
        let response = try await supabase
            .from("clients")
            .select("*")
            .eq("id", value: id)
            .single()
            .execute()

        let client: Contact = try JSONDecoder().decode(Contact.self, from: response.data)
        return client
    }

    func createClient(
        name: String,
        email: String?,
        phone: String?,
        address: String?,
        city: String?,
        state: String?,
        zipCode: String?,
        country: String?,
        contactName: String?,
        notes: String?
    ) async throws -> Contact {
        let scope = try await ownershipResolver.currentScope()
        let insert = ClientInsert(
            organizationId: scope.organizationId,
            userId: scope.organizationId == nil ? scope.userId : nil,
            name: name,
            email: email,
            phone: phone,
            address: address,
            city: city,
            state: state,
            zipCode: zipCode,
            country: country,
            contactName: contactName,
            notes: notes
        )

        let response = try await supabase
            .from("clients")
            .insert(insert)
            .select()
            .single()
            .execute()

        let client: Contact = try JSONDecoder().decode(Contact.self, from: response.data)
        return client
    }

    func updateClient(
        id: String,
        name: String,
        email: String?,
        phone: String?,
        address: String?,
        city: String?,
        state: String?,
        zipCode: String?,
        country: String?,
        contactName: String?,
        notes: String?
    ) async throws -> Contact {
        let scope = try await ownershipResolver.currentScope()
        let update = ClientInsert(
            organizationId: scope.organizationId,
            userId: scope.organizationId == nil ? scope.userId : nil,
            name: name,
            email: email,
            phone: phone,
            address: address,
            city: city,
            state: state,
            zipCode: zipCode,
            country: country,
            contactName: contactName,
            notes: notes
        )

        let response = try await supabase
            .from("clients")
            .update(update)
            .eq("id", value: id)
            .select()
            .single()
            .execute()

        let client: Contact = try JSONDecoder().decode(Contact.self, from: response.data)
        return client
    }

    func deleteClient(id: String) async throws {
        try await supabase
            .from("clients")
            .delete()
            .eq("id", value: id)
            .execute()
    }
}

// MARK: - Insert DTO

struct ClientInsert: Codable {
    let organizationId: String?
    let userId: String?
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

    enum CodingKeys: String, CodingKey {
        case organizationId = "organization_id"
        case userId = "user_id"
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
    }
}
