//
//  AppCoordinator.swift
//  alpha
//
//  Created by Claude Code on 11/25/25.
//

import SwiftUI

struct AppCoordinator: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.isLoading {
                // Loading screen
                LoadingView()
            } else if appState.isAuthenticated {
                // Main app (will create this in Phase 3)
                MainTabView()
            } else {
                // Login screen (will create this in Phase 3)
                LoginView()
            }
        }
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.alphaBackground.ignoresSafeArea()

            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)

                Text("Loading...")
                    .font(.alphaBody)
                    .foregroundColor(.alphaSecondaryText)
            }
        }
    }
}

// Note: LoginView and MainTabView are now in their respective feature folders

// MARK: - Preview

#Preview("Loading") {
    AppCoordinator()
        .environmentObject({
            let state = AppState()
            state.isLoading = true
            return state
        }())
}

#Preview("Not Authenticated") {
    AppCoordinator()
        .environmentObject({
            let state = AppState()
            state.isAuthenticated = false
            return state
        }())
}

#Preview("Authenticated") {
    AppCoordinator()
        .environmentObject({
            let state = AppState()
            state.isAuthenticated = true
            state.currentUser = .preview
            state.organization = .preview
            return state
        }())
}
