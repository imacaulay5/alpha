//
//  MainTabView.swift
//  alpha
//
//  Created by Claude Code on 11/25/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showingQuickEntry = false
    @State private var showingCreateInvoice = false
    @State private var showingQuickPayment = false

    init() {
        // Configure tab bar appearance to fix the selected icon issue
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()

        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }

    var body: some View {
        ZStack {
            // Tab View
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)

                TasksView()
                    .tabItem {
                        Label("Tasks", systemImage: "list.bullet.clipboard")
                    }
                    .tag(1)

                BillingView()
                    .tabItem {
                        Label("Billing", systemImage: "doc.text.fill")
                    }
                    .tag(2)

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(3)
            }
            .tint(.alphaPrimary)

            // Expandable Floating Action Button (appears on all tabs)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ExpandableFAB(
                        primaryAction: {
                            // Long press action - show quick entry
                            showingQuickEntry = true
                        },
                        secondaryActions: [
                            FABAction(
                                icon: "doc.badge.plus",
                                label: "Create Invoice",
                                color: .blue,
                                action: { showingCreateInvoice = true }
                            ),
                            FABAction(
                                icon: "creditcard.fill",
                                label: "Quick Payment",
                                color: .orange,
                                action: { showingQuickPayment = true }
                            )
                        ]
                    )
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
