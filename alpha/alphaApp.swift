//
//  alphaApp.swift
//  alpha
//
//  Created by Iver Macaulay on 11/25/25.
//

import SwiftUI

@main
struct alphaApp: App {
    @StateObject private var appState = AppState()
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            AppCoordinator()
                .environmentObject(appState)
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.colorScheme)
                .task {
                    await appState.checkAuthStatus()
                }
        }
    }
}

