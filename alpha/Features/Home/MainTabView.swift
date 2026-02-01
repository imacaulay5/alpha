//
//  MainTabView.swift
//  alpha
//
//  Created by Claude Code on 11/25/25.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    @State private var showingQuickActions = false
    @State private var showingQuickEntry = false
    @State private var showingCreateInvoice = false
    @State private var showingQuickPayment = false
    @State private var showingCreateProject = false
    @State private var showingAddExpense = false

    init() {
        // Configure tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()

        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }

    // Use the account-type-aware visible tabs from AppState
    var visibleTabs: [MainTab] {
        appState.visibleTabs
    }

    var body: some View {
        ZStack {
            // Dynamic Tab View based on capabilities
            TabView(selection: $selectedTab) {
                ForEach(visibleTabs) { tab in
                    tabContent(for: tab)
                        .tabItem {
                            Label(tab.title, systemImage: tab.icon)
                        }
                        .tag(tab.rawValue)
                }
            }
            .tint(Color(uiColor: .label))

            // Context-aware Floating Action Button
            if let currentTab = visibleTabs.first(where: { $0.rawValue == selectedTab }),
               currentTab != .team {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()

                        switch currentTab {
                        case .home:
                            // Show FAB that opens Quick Actions sheet
                            if hasAnyQuickAction {
                                Button(action: { showingQuickActions = true }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(Color(uiColor: .systemBackground))
                                        .frame(width: 60, height: 60)
                                        .background(
                                            Circle()
                                                .fill(Color(uiColor: .label))
                                                .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
                                        )
                                }
                                .accessibilityLabel("Quick Actions")
                            }

                        case .tasks:
                            if appState.hasCapability(.trackTime) {
                                Button(action: { showingQuickEntry = true }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(Color(uiColor: .systemBackground))
                                        .frame(width: 60, height: 60)
                                        .background(
                                            Circle()
                                                .fill(Color(uiColor: .label))
                                                .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
                                        )
                                }
                                .accessibilityLabel("Log Time")
                            }

                        case .projects:
                            if appState.hasCapability(.createProjects) {
                                Button(action: { showingCreateProject = true }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(Color(uiColor: .systemBackground))
                                        .frame(width: 60, height: 60)
                                        .background(
                                            Circle()
                                                .fill(Color(uiColor: .label))
                                                .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
                                        )
                                }
                                .accessibilityLabel("Create project")
                            }

                        case .billing:
                            if appState.hasCapability(.submitExpenses) {
                                Button(action: { showingAddExpense = true }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(Color(uiColor: .systemBackground))
                                        .frame(width: 60, height: 60)
                                        .background(
                                            Circle()
                                                .fill(Color(uiColor: .label))
                                                .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
                                        )
                                }
                                .accessibilityLabel("Add Expense")
                            }

                        case .team:
                            EmptyView()
                        }

                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 70)
                }
            }
        }
        .sheet(isPresented: $showingQuickActions) {
            QuickActionsSheet(isPresented: $showingQuickActions, actions: quickActions)
        }
        .sheet(isPresented: $showingQuickEntry) {
            QuickEntrySheet(isPresented: $showingQuickEntry)
        }
        .sheet(isPresented: $showingCreateInvoice) {
            CreateInvoiceSheet(isPresented: $showingCreateInvoice)
        }
        .sheet(isPresented: $showingQuickPayment) {
            QuickPaymentSheet(isPresented: $showingQuickPayment)
        }
        .sheet(isPresented: $showingCreateProject) {
            ProjectFormSheet(isPresented: $showingCreateProject, onSave: {})
        }
        .sheet(isPresented: $showingAddExpense) {
            ExpenseFormSheet(isPresented: $showingAddExpense, onSave: {})
        }
    }

    // MARK: - Helper Methods

    @ViewBuilder
    private func tabContent(for tab: MainTab) -> some View {
        switch tab {
        case .home:
            HomeView()
        case .tasks:
            TasksView()
        case .projects:
            ProjectsListView()
        case .billing:
            BillingView()
        case .team:
            TeamView()
        }
    }

    // Quick Actions for the Home tab sheet
    private var quickActions: [QuickAction] {
        var actions: [QuickAction] = []

        if appState.hasCapability(.trackTime) {
            actions.append(QuickAction(
                icon: "clock.fill",
                label: "Log Time",
                color: .purple,
                action: { showingQuickEntry = true }
            ))
        }

        if appState.hasCapability(.createInvoices) {
            actions.append(QuickAction(
                icon: "doc.badge.plus",
                label: "Create Invoice",
                color: .blue,
                action: { showingCreateInvoice = true }
            ))
        }

        if appState.hasCapability(.createProjects) {
            actions.append(QuickAction(
                icon: "folder.badge.plus",
                label: "New Project",
                color: .cyan,
                action: { showingCreateProject = true }
            ))
        }

        if appState.hasCapability(.submitExpenses) {
            actions.append(QuickAction(
                icon: "dollarsign.circle.fill",
                label: "Add Expense",
                color: .green,
                action: { showingAddExpense = true }
            ))
        }

        if appState.hasCapability(.recordPayments) {
            actions.append(QuickAction(
                icon: "creditcard.fill",
                label: "Record Payment",
                color: .orange,
                action: { showingQuickPayment = true }
            ))
        }

        return actions
    }

    private var hasAnyQuickAction: Bool {
        appState.hasCapability(.trackTime) ||
        appState.hasCapability(.createInvoices) ||
        appState.hasCapability(.createProjects) ||
        appState.hasCapability(.submitExpenses) ||
        appState.hasCapability(.recordPayments)
    }
}

// MARK: - Preview

#Preview("Main Tab View") {
    MainTabView()
        .environmentObject({
            let state = AppState()
            state.isAuthenticated = true
            state.currentUser = .preview
            state.organization = .preview
            return state
        }())
}
