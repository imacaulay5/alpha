//
//  CapabilityModifier.swift
//  alpha
//
//  Created by Claude Code
//

import SwiftUI

// MARK: - Single Capability Modifier

/// View modifier that conditionally displays content based on user capability
struct RequiresCapability: ViewModifier {
    @EnvironmentObject var appState: AppState
    let capability: Capability
    let fallback: AnyView?

    func body(content: Content) -> some View {
        if appState.hasCapability(capability) {
            content
        } else if let fallback = fallback {
            fallback
        } else {
            EmptyView()
        }
    }
}

// MARK: - Multiple Capabilities (AND Logic)

/// View modifier for multiple capability requirements (AND logic)
/// User must have ALL specified capabilities to see content
struct RequiresAllCapabilities: ViewModifier {
    @EnvironmentObject var appState: AppState
    let capabilities: [Capability]
    let fallback: AnyView?

    func body(content: Content) -> some View {
        let hasAll = capabilities.allSatisfy { appState.hasCapability($0) }

        if hasAll {
            content
        } else if let fallback = fallback {
            fallback
        } else {
            EmptyView()
        }
    }
}

// MARK: - Multiple Capabilities (OR Logic)

/// View modifier for multiple capability requirements (OR logic)
/// User needs ANY of the specified capabilities to see content
struct RequiresAnyCapability: ViewModifier {
    @EnvironmentObject var appState: AppState
    let capabilities: [Capability]
    let fallback: AnyView?

    func body(content: Content) -> some View {
        let hasAny = capabilities.contains { appState.hasCapability($0) }

        if hasAny {
            content
        } else if let fallback = fallback {
            fallback
        } else {
            EmptyView()
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Show view only if user has the specified capability
    ///
    /// Example:
    /// ```swift
    /// Button("Create Invoice") { }
    ///     .requiresCapability(.createInvoices)
    /// ```
    func requiresCapability(
        _ capability: Capability,
        fallback: AnyView? = nil
    ) -> some View {
        modifier(RequiresCapability(capability: capability, fallback: fallback))
    }

    /// Show view only if user has ALL specified capabilities
    ///
    /// Example:
    /// ```swift
    /// NavigationLink("Team Billing") { TeamBillingView() }
    ///     .requiresAllCapabilities(.viewTeamTimeEntries, .viewInvoices)
    /// ```
    func requiresAllCapabilities(
        _ capabilities: Capability...,
        fallback: AnyView? = nil
    ) -> some View {
        modifier(RequiresAllCapabilities(capabilities: capabilities, fallback: fallback))
    }

    /// Show view only if user has ANY of the specified capabilities
    ///
    /// Example:
    /// ```swift
    /// Section("Approvals") { }
    ///     .requiresAnyCapability(.approveTimeEntries, .approveExpenses)
    /// ```
    func requiresAnyCapability(
        _ capabilities: Capability...,
        fallback: AnyView? = nil
    ) -> some View {
        modifier(RequiresAnyCapability(capabilities: capabilities, fallback: fallback))
    }
}
