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

// MARK: - Capability Helpers

extension AppState {
    /// Check if current user has a specific capability
    func hasCapability(_ capability: Capability) -> Bool {
        currentUser?.hasCapability(capability) ?? false
    }

    /// Determines which main tabs should be visible based on user capabilities and account type
    var visibleTabs: [MainTab] {
        guard let user = currentUser else { return [.home] }

        var tabs: [MainTab] = [.home]

        // Business accounts have a different tab structure
        if user.accountType == .business {
            // Business: Home, Projects, Billing, Team
            if user.hasCapability(.viewProjects) {
                tabs.append(.projects)
            }

            if user.canAccessBilling {
                tabs.append(.billing)
            }

            if user.canManageTeam {
                tabs.append(.team)
            }
        } else {
            // Personal/Freelancer: Home, Tasks, Billing, Projects
            // Tasks tab - visible if user can track time
            if user.hasCapability(.trackTime) || user.hasCapability(.viewOwnTimeEntries) {
                tabs.append(.tasks)
            }

            // Billing tab - visible if user can access billing features
            if user.canAccessBilling {
                tabs.append(.billing)
            }

            // Projects tab - visible for users with project capabilities
            if user.hasCapability(.viewProjects) {
                tabs.append(.projects)
            }
        }

        return tabs
    }

    /// Feature modules available to the user (for future expansion)
    var availableModules: Set<AppModule> {
        guard let user = currentUser else { return [] }

        var modules: Set<AppModule> = [.dashboard, .settings]

        if user.hasCapability(.trackTime) {
            modules.insert(.timeTracking)
        }

        if user.canManageInvoices {
            modules.insert(.invoicing)
        }

        if user.hasCapability(.viewAccountsReceivable) || user.hasCapability(.viewAccountsPayable) {
            modules.insert(.accounting)
        }

        if user.canAccessPayroll {
            modules.insert(.payroll)
        }

        if user.canAccessInventory {
            modules.insert(.inventory)
        }

        if user.hasCapability(.viewTaxDashboard) {
            modules.insert(.taxCompliance)
        }

        if user.canManageTeam {
            modules.insert(.teamManagement)
        }

        return modules
    }
}

// MARK: - App Module Definition

/// Future module structure for app expansion
enum AppModule: String, CaseIterable, Hashable {
    case dashboard
    case timeTracking
    case invoicing
    case accounting
    case payroll
    case inventory
    case taxCompliance
    case teamManagement
    case settings

    var icon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .timeTracking: return "clock.fill"
        case .invoicing: return "doc.text.fill"
        case .accounting: return "chart.bar.fill"
        case .payroll: return "dollarsign.circle.fill"
        case .inventory: return "shippingbox.fill"
        case .taxCompliance: return "doc.plaintext.fill"
        case .teamManagement: return "person.3.fill"
        case .settings: return "gearshape.fill"
        }
    }

    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .timeTracking: return "Time Tracking"
        case .invoicing: return "Invoicing"
        case .accounting: return "Accounting"
        case .payroll: return "Payroll"
        case .inventory: return "Inventory"
        case .taxCompliance: return "Tax & Compliance"
        case .teamManagement: return "Team"
        case .settings: return "Settings"
        }
    }
}

// MARK: - Main Tab Definition

/// Main tabs for the app navigation
enum MainTab: Int, Identifiable, CaseIterable {
    case home = 0
    case tasks = 1
    case projects = 2
    case billing = 3
    case team = 4

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home: return "Home"
        case .tasks: return "Tasks"
        case .projects: return "Projects"
        case .billing: return "Billing"
        case .team: return "Team"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .tasks: return "list.bullet.clipboard"
        case .projects: return "folder.fill"
        case .billing: return "doc.text.fill"
        case .team: return "person.3.fill"
        }
    }

    /// Capability required to see this tab (nil = always visible)
    var requiredCapability: Capability? {
        switch self {
        case .home:
            return nil // Always visible
        case .tasks:
            return .trackTime
        case .projects:
            return .viewProjects
        case .billing:
            return .viewInvoices
        case .team:
            return .manageUsers // Only for business accounts with team management
        }
    }
}
