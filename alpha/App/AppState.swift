//
//  AppState.swift
//  alpha
//
//  Created by Claude Code on 11/25/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var organization: Organization?
    @Published var isLoading = false
    @Published var error: String?

    private let authService = AuthService.shared

    // MARK: - Initialization

    func checkAuthStatus() async {
        isLoading = true

        let isAuth = await authService.checkAuthStatus()

        if isAuth {
            // Fetch current user and organization
            do {
                let user = try await authService.getCurrentUser()
                self.currentUser = user
                self.isAuthenticated = true

                // TODO: Fetch organization
                // For now, we'll wait for the login response to provide it
            } catch {
                print("Failed to fetch current user: \(error)")
                isAuthenticated = false
                currentUser = nil
                organization = nil
            }
        } else {
            isAuthenticated = false
            currentUser = nil
            organization = nil
        }

        isLoading = false
    }

    // MARK: - Authentication

    func login(user: User, organization: Organization) {
        self.currentUser = user
        self.organization = organization
        self.isAuthenticated = true
        self.error = nil
    }

    func logout() {
        self.currentUser = nil
        self.organization = nil
        self.isAuthenticated = false
        self.error = nil
    }

    // MARK: - Error Handling

    func setError(_ message: String) {
        self.error = message
    }

    func clearError() {
        self.error = nil
    }
}
