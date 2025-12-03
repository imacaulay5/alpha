//
//  AuthService.swift
//  alpha
//
//  Created by Claude Code on 11/25/25.
//

import Foundation
import Combine

@MainActor
class AuthService {
    static let shared = AuthService()

    private let apiClient = APIClient.shared
    private let keychainHelper = KeychainHelper.shared

    private init() {}

    // MARK: - Authentication State

    var isAuthenticated: Bool {
        keychainHelper.hasAccessToken
    }

    // MARK: - Login

    struct LoginRequest: Encodable {
        let email: String
        let password: String
    }

    struct LoginResponse: Decodable {
        let user: User
        let organization: Organization
        let accessToken: String
        let refreshToken: String

        enum CodingKeys: String, CodingKey {
            case user
            case organization
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
        }
    }

    func login(email: String, password: String) async throws -> (User, Organization) {
        let request = LoginRequest(email: email, password: password)

        let response: LoginResponse = try await apiClient.post("/auth/login", body: request)

        // Store tokens in keychain
        try keychainHelper.saveAccessToken(response.accessToken)
        try keychainHelper.saveRefreshToken(response.refreshToken)

        return (response.user, response.organization)
    }

    // MARK: - Logout

    func logout() async throws {
        // Clear tokens from keychain
        try keychainHelper.clearTokens()

        // Optionally notify backend (if you have a logout endpoint)
        // try? await apiClient.post("/auth/logout", body: EmptyRequest())
    }

    // MARK: - Token Refresh

    struct RefreshRequest: Encodable {
        let refreshToken: String

        enum CodingKeys: String, CodingKey {
            case refreshToken = "refresh_token"
        }
    }

    struct RefreshResponse: Decodable {
        let accessToken: String

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
        }
    }

    func refreshToken() async throws -> String {
        guard let refreshToken = try keychainHelper.getRefreshToken() else {
            throw APIError.unauthorized
        }

        let request = RefreshRequest(refreshToken: refreshToken)
        let response: RefreshResponse = try await apiClient.post("/auth/refresh", body: request)

        // Save new access token
        try keychainHelper.saveAccessToken(response.accessToken)

        return response.accessToken
    }

    // MARK: - Get Current User

    func getCurrentUser() async throws -> User {
        let user: User = try await apiClient.get("/auth/me")
        return user
    }

    // MARK: - Check Auth Status

    func checkAuthStatus() async -> Bool {
        // Check if we have tokens
        guard keychainHelper.hasAccessToken else {
            return false
        }

        // Optionally verify token is still valid by fetching current user
        do {
            _ = try await getCurrentUser()
            return true
        } catch {
            // Token is invalid, clear it
            try? keychainHelper.clearTokens()
            return false
        }
    }
}

// MARK: - Helper Types

private struct EmptyRequest: Encodable {}
