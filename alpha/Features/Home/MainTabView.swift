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

            // Context-aware Floating Action Button
            if selectedTab != 3 { // Hide on Settings tab
                VStack {
                    Spacer()
                    HStack {
                        Spacer()

                        switch selectedTab {
                        case 0: // Home tab - Expandable menu
                            ExpandableFAB(
                                primaryAction: {
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

                        case 1: // Tasks tab - Simple create invoice button
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

                        case 2: // Billing tab - Simple Quick Bill button
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

                        default:
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
