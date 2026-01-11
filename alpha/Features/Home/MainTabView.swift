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
    @State private var showingQuickEntry = false
    @State private var showingCreateInvoice = false
    @State private var showingQuickPayment = false
    @State private var showingQuickBill = false

    init() {
        // Configure tab bar appearance to fix the selected icon issue
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()

        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }

    // Dynamically filter tabs based on user capabilities
    var visibleTabs: [MainTab] {
        MainTab.allCases.filter { tab in
            guard let required = tab.requiredCapability else { return true }
            return appState.hasCapability(required)
        }
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
            .tint(.alphaPrimary)

            // Context-aware Floating Action Button
            if let currentTab = visibleTabs.first(where: { $0.rawValue == selectedTab }),
               currentTab != .settings {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()

                        switch currentTab {
                        case .home: // Home tab - Expandable menu with capability-filtered actions
                            let actions = homeActions.filter { action in
                                guard let required = action.requiredCapability else { return true }
                                return appState.hasCapability(required)
                            }

                            if !actions.isEmpty {
                                ExpandableFAB(
                                    primaryAction: {
                                        showingQuickEntry = true
                                    },
                                    secondaryActions: actions
                                )
                            }

                        case .tasks: // Tasks tab - Simple create invoice button (if can create invoices)
                            if appState.hasCapability(.createInvoices) {
                                Button(action: { showingCreateInvoice = true }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(width: 60, height: 60)
                                        .background(
                                            Circle()
                                                .fill(Color.alphaPrimary)
                                                .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
                                        )
                                }
                                .accessibilityLabel("Create invoice")
                            }

                        case .billing: // Billing tab - Quick Bill button (if has capability)
                            if appState.hasCapability(.quickBill) {
                                Button(action: { showingQuickBill = true }) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(width: 60, height: 60)
                                        .background(
                                            Circle()
                                                .fill(Color.alphaPrimary)
                                                .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
                                        )
                                }
                                .accessibilityLabel("Quick Bill")
                            }

                        case .settings:
                            EmptyView()
                        }

                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 70)
                }
            }
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
        .sheet(isPresented: $showingQuickBill) {
            QuickBillSheet(isPresented: $showingQuickBill)
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
        case .billing:
            BillingView()
        case .settings:
            SettingsView()
        }
    }

    // Home tab FAB actions with capability requirements
    private var homeActions: [FABAction] {
        [
            FABAction(
                icon: "doc.badge.plus",
                label: "Create Invoice",
                color: .blue,
                requiredCapability: .createInvoices,
                action: { showingCreateInvoice = true }
            ),
            FABAction(
                icon: "creditcard.fill",
                label: "Quick Payment",
                color: .orange,
                requiredCapability: .recordPayments,
                action: { showingQuickPayment = true }
            )
        ]
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
