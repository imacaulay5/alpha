//
//  SupabaseClient.swift
//  alpha
//
//  Created by Claude Code on 12/18/24.
//

import Foundation
import Supabase

class SupabaseClientManager {
    static let shared = SupabaseClientManager()

    let client: SupabaseClient

    private init() {
        let config = SupabaseConfig.shared

        self.client = SupabaseClient(
            supabaseURL: config.projectURL,
            supabaseKey: config.anonKey,
            options: SupabaseClientOptions(
                auth: .init(
                    flowType: .pkce,
                    autoRefreshToken: true,
                    emitLocalSessionAsInitialSession: true
                )
            )
        )

        print("🔧 SupabaseClient: Initialized with URL: \(config.projectURL)")
        print("🔧 SupabaseClient: Using anon key: \(config.anonKey.prefix(20))...")
    }
}

struct OwnershipScope {
    let userId: String
    let organizationId: String?

    var usesOrganization: Bool {
        organizationId != nil
    }
}

final class OwnershipResolver {
    private let supabase = SupabaseClientManager.shared.client

    func currentScope() async throws -> OwnershipScope {
        guard let userId = supabase.auth.currentSession?.user.id.uuidString else {
            throw AuthError.notAuthenticated
        }

        let user: User = try await supabase
            .from("users")
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value

        return OwnershipScope(userId: user.id, organizationId: user.organizationId)
    }
}
