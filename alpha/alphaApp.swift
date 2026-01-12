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
    @AppStorage("appearance") private var appearance: String = "system"

    var body: some Scene {
        WindowGroup {
            AppCoordinator()
                .environmentObject(appState)
                .preferredColorScheme(colorScheme)
                .task {
                    await appState.checkAuthStatus()
                }
        }
    }

    private var colorScheme: ColorScheme? {
        switch appearance {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil // System default
        }
    }
}

