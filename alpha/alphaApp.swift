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

    var body: some Scene {
        WindowGroup {
            AppCoordinator()
                .environmentObject(appState)
                .task {
                    await appState.checkAuthStatus()
                }
        }
    }
}
