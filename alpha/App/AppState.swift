//
//  AppState.swift
//  alpha
//
//  Created by Claude Code on 11/25/25.
//

import Foundation
import SwiftUI
import Combine
import Auth

@MainActor
class AppState: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var organization: Organization?
    @Published var isLoading = false
    @Published var error: String?

    private let authService = AuthService.shared
    private var authStateTask: Task<Void, Never>?

    // MARK: - Initialization

    init() {
        // Observe auth state changes
        authStateTask = authService.observeAuthStateChanges { [weak self] event, session in
            Task { @MainActor in
                switch event {
                case .signedIn:
                    await self?.onSignedIn()
                case .signedOut:
                    self?.onSignedOut()
                default:
                    break
                }
            }
        }
    }

    deinit {
        authStateTask?.cancel()
    }

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

    func login(user: User, organization: Organization?) {
        self.currentUser = user
        self.organization = organization  // Can be nil for personal/freelancer accounts
        self.isAuthenticated = true
        self.error = nil
    }

    var requiresOrganization: Bool {
        currentUser?.accountType.requiresOrganization ?? false
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

    // MARK: - Private Helpers

    private func onSignedIn() async {
        do {
            // Use getUserInfo() instead of getCurrentUser() to handle new users
            // who don't have a database record yet
            if let user = try await authService.getUserInfo() {
                self.currentUser = user
                self.isAuthenticated = true
                print("✅ AppState.onSignedIn: User found in database")
            } else {
                // User authenticated but no database record yet (new user during signup)
                print("ℹ️ AppState.onSignedIn: User authenticated but no database record yet")
                // Don't set isAuthenticated here - let the signup/login flow handle it
            }
        } catch {
            print("❌ AppState.onSignedIn: Error fetching user: \(error)")
            onSignedOut()
        }
    }

    private func onSignedOut() {
        self.currentUser = nil
        self.organization = nil
        self.isAuthenticated = false
    }
}
