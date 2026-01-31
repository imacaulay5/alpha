//
//  AccountSheet.swift
//  alpha
//
//  Created by Claude Code on 1/31/26.
//

import SwiftUI

struct AccountSheet: View {
    @EnvironmentObject var appState: AppState
    @Binding var isPresented: Bool
    @State private var showingSignOutConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                Section {
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Color.alphaPrimary)
                            .frame(width: 60, height: 60)
                            .overlay {
                                Text(appState.currentUser?.initials ?? "")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(appState.currentUser?.name ?? "User")
                                .font(.headline)

                            Text(appState.currentUser?.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            if let accountType = appState.currentUser?.accountType {
                                Text(accountType.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Organization Section
                if let org = appState.organization {
                    Section("Organization") {
                        HStack {
                            Label("Company", systemImage: "building.2")
                            Spacer()
                            Text(org.name)
                                .foregroundColor(.secondary)
                        }

                        if let email = org.email {
                            HStack {
                                Label("Email", systemImage: "envelope")
                                Spacer()
                                Text(email)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // Actions Section
                Section {
                    NavigationLink(destination: SettingsView()) {
                        Label("Settings", systemImage: "gearshape")
                    }
                }

                // Sign Out Section
                Section {
                    Button(role: .destructive) {
                        showingSignOutConfirmation = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
            .confirmationDialog(
                "Are you sure you want to sign out?",
                isPresented: $showingSignOutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) {
                    Task {
                        try? await AuthService.shared.logout()
                        appState.logout()
                        isPresented = false
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

// MARK: - Preview

#Preview("Account Sheet") {
    AccountSheet(isPresented: .constant(true))
        .environmentObject({
            let state = AppState()
            state.currentUser = .preview
            state.organization = .preview
            return state
        }())
}
