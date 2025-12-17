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
                DashboardView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)

                TimeTrackingView()
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

            // Floating Action Button (appears on all tabs)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingActionButton {
                        showingQuickEntry = true
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .sheet(isPresented: $showingQuickEntry) {
            QuickEntrySheet(isPresented: $showingQuickEntry)
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
