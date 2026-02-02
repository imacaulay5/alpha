//
//  ThemeManager.swift
//  alpha
//
//  Created by Claude Code on 2/1/26.
//

import SwiftUI
import UIKit
import Combine

@MainActor
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var colorScheme: ColorScheme?

    private var cancellable: AnyCancellable?

    private init() {
        // Read initial value from UserDefaults
        updateColorScheme(from: UserDefaults.standard.string(forKey: "appearance") ?? "system")

        // Observe changes to the appearance key
        cancellable = UserDefaults.standard.publisher(for: \.appearance)
            .sink { [weak self] newValue in
                self?.updateColorScheme(from: newValue ?? "system")
            }
    }

    private func updateColorScheme(from appearance: String) {
        switch appearance {
        case "light":
            colorScheme = .light
        case "dark":
            colorScheme = .dark
        default:
            colorScheme = nil
        }

        // Also update all windows for UIKit components
        updateWindowAppearance(appearance)
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

        for scene in UIApplication.shared.connectedScenes {
            if let windowScene = scene as? UIWindowScene {
                for window in windowScene.windows {
                    window.overrideUserInterfaceStyle = style
                }
            }
        }
    }
}

// MARK: - UserDefaults Extension for KVO

extension UserDefaults {
    @objc dynamic var appearance: String? {
        string(forKey: "appearance")
    }
}

// MARK: - View Modifier

struct ThemedSheetModifier: ViewModifier {
    @ObservedObject private var themeManager = ThemeManager.shared

    func body(content: Content) -> some View {
        content
            .preferredColorScheme(themeManager.colorScheme)
    }
}

extension View {
    func withAppTheme() -> some View {
        modifier(ThemedSheetModifier())
    }
}
