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
                    autoRefreshToken: true
                )
            )
        )

        print("🔧 SupabaseClient: Initialized with URL: \(config.projectURL)")
        print("🔧 SupabaseClient: Using anon key: \(config.anonKey.prefix(20))...")
    }
}
