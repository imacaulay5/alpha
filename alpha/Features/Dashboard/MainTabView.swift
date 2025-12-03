//
//  MainTabView.swift
//  alpha
//
//  Created by Claude Code on 11/25/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

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
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
                .tag(0)

            TimeTrackingView()
                .tabItem {
                    Label("Time", systemImage: "timer")
                }
                .tag(1)

            ExpenseView()
                .tabItem {
                    Label("Expenses", systemImage: "dollarsign.circle.fill")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(.alphaPrimary)
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
