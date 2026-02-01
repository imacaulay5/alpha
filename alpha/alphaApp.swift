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
                .onChange(of: appearance) { _, newValue in
                    updateWindowAppearance(newValue)
                }
                .onAppear {
                    updateWindowAppearance(appearance)
                }
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

    private func updateWindowAppearance(_ appearance: String) {
        let style: UIUserInterfaceStyle
        switch appearance {
        case "light":
            style = .light
        case "dark":
            style = .dark
        default:
            style = .unspecified
        }

        // Update all windows immediately
        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene {
                for window in windowScene.windows {
                    window.overrideUserInterfaceStyle = style
                }
            }
        }
    }
}

