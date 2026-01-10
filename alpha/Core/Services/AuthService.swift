//
//  AuthService.swift
//  alpha
//
//  Created by Claude Code on 11/25/25.
//  Updated for Supabase on 12/18/24.
//

import Foundation
import Supabase

@MainActor
class AuthService {
    static let shared = AuthService()

    private let supabase = SupabaseClientManager.shared.client

    private init() {}

    // MARK: - Authentication State

    var isAuthenticated: Bool {
        supabase.auth.currentSession != nil
    }

    var currentSession: Session? {
        supabase.auth.currentSession
    }

    // MARK: - Login

    func login(email: String, password: String) async throws -> (User, Organization?) {
        // Sign in with Supabase Auth
        let session = try await supabase.auth.signIn(
            email: email,
            password: password
        )

        // Fetch user data from database
        let user: User = try await supabase
            .from("users")
            .select()
            .eq("id", value: session.user.id.uuidString)
            .single()
            .execute()
            .value

        // Fetch organization data if user has one
        let organization: Organization?
        if let orgId = user.organizationId {
            organization = try await supabase
                .from("organizations")
                .select()
                .eq("id", value: orgId)
                .single()
                .execute()
                .value
        } else {
            organization = nil
        }

        return (user, organization)
    }

    // MARK: - Logout

    func logout() async throws {
        try await supabase.auth.signOut()
    }

    // MARK: - Get Current User

    func getCurrentUser() async throws -> User {
        guard let session = supabase.auth.currentSession else {
            throw AuthError.notAuthenticated
        }

        let user: User = try await supabase
            .from("users")
            .select()
            .eq("id", value: session.user.id.uuidString)
            .single()
            .execute()
            .value

        return user
    }

    // MARK: - Get User Info (returns nil if not exists)

    func getUserInfo() async throws -> User? {
        guard let userId = supabase.auth.currentSession?.user.id else {
            throw AuthError.notAuthenticated
        }

        do {
            // Configure decoder for Supabase's timestamp format
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let response = try await supabase
                .from("users")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()

            let user = try decoder.decode(User.self, from: response.data)
            return user
        } catch {
            // User doesn't exist in database yet
            return nil
        }
    }

    // MARK: - Create Personal User (no organization)

    func createPersonalUser(name: String, accountType: AccountType) async throws -> User {
        guard let session = supabase.auth.currentSession else {
            throw AuthError.notAuthenticated
        }

        let userId = session.user.id
        let email = session.user.email ?? ""

        print("👤 AuthService.createPersonalUser: Creating \(accountType.displayName) user")

        let userInsert = PersonalUserInsert(
            id: userId.uuidString,
            email: email,
            name: name,
            accountType: accountType.rawValue,
            role: accountType.defaultRole
        )

        // Configure decoder for Supabase's timestamp format
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let response = try await supabase
            .from("users")
            .insert(userInsert)
            .select()
            .single()
            .execute()

        let user = try decoder.decode(User.self, from: response.data)
        print("✅ AuthService.createPersonalUser: Personal user created")

        return user
    }

    // MARK: - Get Organization

    func getOrganization(_ organizationId: String) async throws -> Organization {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let organization: Organization = try await supabase
            .from("organizations")
            .select()
            .eq("id", value: organizationId)
            .single()
            .execute()
            .value

        return organization
    }

    // MARK: - Session Management

    func observeAuthStateChanges(handler: @escaping (AuthChangeEvent, Session?) -> Void) -> Task<Void, Never> {
        Task {
            for await (event, _session) in supabase.auth.authStateChanges {
                await MainActor.run {
                    handler(event, _session)
                }
            }
        }
    }

    // MARK: - Check Auth Status

    func checkAuthStatus() async -> Bool {
        guard supabase.auth.currentSession != nil else {
            return false
        }

        // Verify session is still valid
        do {
            _ = try await getCurrentUser()
            return true
        } catch {
            try? await supabase.auth.signOut()
            return false
        }
    }

    // MARK: - Sign Up

    func signUp(email: String, password: String, name: String) async throws {
        // Create auth user with name in metadata
        print("🔐 AuthService.signUp: Creating user with name: \(name)")

        _ = try await supabase.auth.signUp(
            email: email,
            password: password,
            data: ["name": .string(name)]
        )
        print("✅ AuthService.signUp: User created")
    }

    // MARK: - Sign In with Password

    func signInWithPassword(email: String, password: String) async throws {
        print("🔐 AuthService.signInWithPassword: Signing in \(email)")
        let response = try await supabase.auth.signIn(
            email: email,
            password: password
        )
        print("✅ AuthService.signInWithPassword: Sign in successful")
        print("🔐 AuthService.signInWithPassword: User role: \(response.user.role ?? "none")")

        // Refresh session to ensure we have "authenticated" role
        // This mirrors the pattern in verifyOTP() which successfully gets authenticated role
        print("🔄 AuthService.signInWithPassword: Refreshing session to ensure authenticated role...")
        let refreshedSession = try await supabase.auth.refreshSession()
        print("✅ AuthService.signInWithPassword: Session refreshed with authenticated role")
        print("🔑 AuthService.signInWithPassword: Access token: \(refreshedSession.accessToken.prefix(30))...")
    }

    // MARK: - Sign Out

    func signOut() async throws {
        print("🔐 AuthService.signOut: Signing out")
        try await supabase.auth.signOut()
        print("✅ AuthService.signOut: Sign out successful")
    }

    // MARK: - Email Verification (OTP)

    func verifyOTP(email: String, token: String) async throws -> Session {
        print("🔐 AuthService.verifyOTP: Starting OTP verification for \(email)")

        let response = try await supabase.auth.verifyOTP(
            email: email,
            token: token,
            type: .signup
        )

        print("🔐 AuthService.verifyOTP: OTP verified for user: \(response.user.id)")
        print("🔐 AuthService.verifyOTP: User role from response: \(response.user.role ?? "none")")

        // Session might be in the response or need to be fetched
        if let responseSession = response.session {
            print("🔐 AuthService.verifyOTP: Session found in response")
            print("🔐 AuthService.verifyOTP: Access token: \(responseSession.accessToken.prefix(30))...")
            print("🔐 AuthService.verifyOTP: Token type: \(responseSession.tokenType)")
            print("🔐 AuthService.verifyOTP: Refresh token: \(responseSession.refreshToken.prefix(30))...")

            // CRITICAL: Refresh the session to get a new JWT with the "authenticated" role
            // After OTP verification, the JWT might still have role: "anon"
            // Refreshing ensures we get a JWT with role: "authenticated"
            print("🔄 AuthService.verifyOTP: Refreshing session to get authenticated role...")

            do {
                let refreshedSession = try await supabase.auth.refreshSession()
                print("✅ AuthService.verifyOTP: Session refreshed")
                print("🔐 AuthService.verifyOTP: New access token: \(refreshedSession.accessToken.prefix(30))...")

                // Verify the refreshed session is stored
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

                if let storedSession = supabase.auth.currentSession {
                    print("✅ AuthService.verifyOTP: Refreshed session stored in client: \(storedSession.user.id)")
                    print("✅ AuthService.verifyOTP: Tokens match: \(storedSession.accessToken == refreshedSession.accessToken)")
                } else {
                    print("⚠️ AuthService.verifyOTP: WARNING - Refreshed session not stored in client!")
                }

                return refreshedSession
            } catch {
                print("⚠️ AuthService.verifyOTP: Session refresh failed: \(error)")
                print("⚠️ AuthService.verifyOTP: Falling back to original session")

                // Fall back to original session if refresh fails
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

                if let storedSession = supabase.auth.currentSession {
                    print("✅ AuthService.verifyOTP: Original session stored in client: \(storedSession.user.id)")
                }

                return responseSession
            }
        }

        // Verify session is now available from currentSession
        guard let currentSession = supabase.auth.currentSession else {
            print("⚠️ AuthService.verifyOTP: Warning - session not immediately available after verifyOTP")
            // Force a small delay for session to be stored
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

            guard let retrySession = supabase.auth.currentSession else {
                print("❌ AuthService.verifyOTP: Session not available after retry")
                throw AuthError.sessionNotEstablished
            }
            print("✅ AuthService.verifyOTP: Session available after retry")
            return retrySession
        }

        print("✅ AuthService.verifyOTP: Session immediately available from currentSession")
        return currentSession
    }

    func resendOTP(email: String) async throws {
        print("📧 AuthService: Resending OTP to \(email)")
        try await supabase.auth.resend(email: email, type: .signup)
        print("✅ AuthService: OTP resend request sent")
    }

    // MARK: - Organization Check

    func userHasOrganization() async throws -> Bool {
        guard let userId = supabase.auth.currentSession?.user.id else {
            print("⚠️ AuthService.userHasOrganization: No active session")
            return false
        }

        print("🔍 AuthService.userHasOrganization: Checking for user: \(userId)")

        do {
            _ = try await supabase
                .from("users")
                .select("organization_id")
                .eq("id", value: userId.uuidString)
                .single()
                .execute()

            // If we get here, user exists in the users table
            print("✅ AuthService.userHasOrganization: User has organization")
            return true
        } catch {
            // User doesn't exist in users table yet (no organization)
            print("❌ AuthService.userHasOrganization: User has no organization: \(error)")
            return false
        }
    }

    // MARK: - Setup Organization (Called after signup during onboarding)

    func setupOrganization(name: String, companyName: String) async throws -> (User, Organization) {
        print("🏢 AuthService.setupOrganization: Starting organization setup")

        // Try to get session with retry
        var session: Session?
        var attempts = 0
        let maxAttempts = 3

        while attempts < maxAttempts {
            session = supabase.auth.currentSession
            if session != nil {
                break
            }

            attempts += 1
            print("⚠️ AuthService.setupOrganization: Attempt \(attempts)/\(maxAttempts) - Session not found, waiting...")
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }

        guard let session = session else {
            print("❌ AuthService.setupOrganization: No active session found after \(maxAttempts) attempts")
            throw AuthError.notAuthenticated
        }

        let userId = session.user.id
        let email = session.user.email ?? ""
        print("✅ AuthService.setupOrganization: Session found for user: \(userId)")
        print("📧 AuthService.setupOrganization: Email: \(email)")
        print("🔐 AuthService.setupOrganization: Email confirmed: \(session.user.emailConfirmedAt != nil)")
        print("🔑 AuthService.setupOrganization: Access token: \(session.accessToken.prefix(30))...")
        print("🔑 AuthService.setupOrganization: Token type: \(session.tokenType)")

        // Verify the supabase client is using this session
        if let currentClientSession = supabase.auth.currentSession {
            print("✅ AuthService.setupOrganization: Supabase client has session: \(currentClientSession.user.id)")
            print("🔑 AuthService.setupOrganization: Client token matches: \(currentClientSession.accessToken == session.accessToken)")
        } else {
            print("⚠️ AuthService.setupOrganization: WARNING - Supabase client has NO session!")
        }

        // Step 1: Create organization
        print("🏢 AuthService.setupOrganization: Creating organization '\(companyName)'")
        let orgInsert = OrganizationInsert(
            name: companyName,
            email: email
        )

        do {
            // DEBUG: Print the actual request details
            print("🔍 AuthService.setupOrganization: About to insert organization")
            print("🔍 AuthService.setupOrganization: Data: \(orgInsert)")

            let orgResponse = try await supabase
                .from("organizations")
                .insert(orgInsert)
                .select()
                .single()
                .execute()

            // Configure decoder for Supabase's timestamp format
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let organization: Organization = try decoder.decode(Organization.self, from: orgResponse.data)
            print("✅ AuthService.setupOrganization: Organization created with ID: \(organization.id)")

            // Step 2: Create user record linked to organization
            print("👤 AuthService.setupOrganization: Creating user record")
            let userInsert = UserInsert(
                id: userId.uuidString,
                organizationId: organization.id,
                email: email,
                name: name,
                role: "OWNER",
                accountType: "business"
            )

            let userResponse = try await supabase
                .from("users")
                .insert(userInsert)
                .select()
                .single()
                .execute()

            let user: User = try decoder.decode(User.self, from: userResponse.data)
            print("✅ AuthService.setupOrganization: User record created")
            print("✅ AuthService.setupOrganization: Organization setup complete!")

            return (user, organization)
        } catch {
            print("❌ AuthService.setupOrganization: Failed with error: \(error)")
            print("❌ AuthService.setupOrganization: Error details: \(error.localizedDescription)")

            // Print detailed error information
            print("❌ Error type: \(type(of: error))")
            print("❌ Error description: \(error.localizedDescription)")

            throw error
        }
    }
}

// MARK: - Auth Errors

enum AuthError: Error, LocalizedError {
    case notAuthenticated
    case signUpFailed
    case sessionNotEstablished

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .signUpFailed:
            return "Failed to sign up user"
        case .sessionNotEstablished:
            return "Session could not be established after verification"
        }
    }
}

// MARK: - Insert DTOs

struct OrganizationInsert: Codable {
    let name: String
    let email: String
}

struct UserInsert: Codable {
    let id: String
    let organizationId: String
    let email: String
    let name: String
    let role: String
    let accountType: String

    enum CodingKeys: String, CodingKey {
        case id
        case organizationId = "organization_id"
        case email
        case name
        case role
        case accountType = "account_type"
    }
}

struct PersonalUserInsert: Codable {
    let id: String
    let email: String
    let name: String
    let accountType: String
    let role: String

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case accountType = "account_type"
        case role
    }
}

