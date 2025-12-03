//
//  AlphaButton.swift
//  alpha
//
//  Created by Claude Code on 11/25/25.
//

import SwiftUI

enum AlphaButtonStyle {
    case primary
    case secondary
    case outline
    case text

    var backgroundColor: Color {
        switch self {
        case .primary:
            return .alphaPrimary
        case .secondary:
            return .alphaSecondary
        case .outline, .text:
            return .clear
        }
    }

    var foregroundColor: Color {
        switch self {
        case .primary, .secondary:
            return .white
        case .outline, .text:
            return .alphaPrimary
        }
    }

    var borderColor: Color? {
        switch self {
        case .outline:
            return .alphaPrimary
        case .primary, .secondary, .text:
            return nil
        }
    }
}

enum AlphaButtonSize {
    case small
    case medium
    case large

    var height: CGFloat {
        switch self {
        case .small:
            return 36
        case .medium:
            return 44
        case .large:
            return 52
        }
    }

    var fontSize: CGFloat {
        switch self {
        case .small:
            return 14
        case .medium:
            return 16
        case .large:
            return 18
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .small:
            return 16
        case .medium:
            return 20
        case .large:
            return 24
        }
    }
}

struct AlphaButton: View {
    let title: String
    let style: AlphaButtonStyle
    let size: AlphaButtonSize
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    init(
        _ title: String,
        style: AlphaButtonStyle = .primary,
        size: AlphaButtonSize = .medium,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                        .scaleEffect(0.8)
                }

                Text(title)
                    .font(.system(size: size.fontSize, weight: .semibold))
                    .foregroundColor(style.foregroundColor)
            }
            .frame(maxWidth: .infinity)
            .frame(height: size.height)
            .padding(.horizontal, size.horizontalPadding)
            .background(style.backgroundColor)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(style.borderColor ?? .clear, lineWidth: 1.5)
            )
        }
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.6 : 1.0)
    }
}

// MARK: - Preview

#Preview("Button Styles") {
    VStack(spacing: 16) {
        AlphaButton("Primary Button", style: .primary) {}
        AlphaButton("Secondary Button", style: .secondary) {}
        AlphaButton("Outline Button", style: .outline) {}
        AlphaButton("Text Button", style: .text) {}
    }
    .padding()
}

#Preview("Button Sizes") {
    VStack(spacing: 16) {
        AlphaButton("Small", style: .primary, size: .small) {}
        AlphaButton("Medium", style: .primary, size: .medium) {}
        AlphaButton("Large", style: .primary, size: .large) {}
    }
    .padding()
}

#Preview("Button States") {
    VStack(spacing: 16) {
        AlphaButton("Loading", style: .primary, isLoading: true) {}
        AlphaButton("Disabled", style: .primary, isDisabled: true) {}
        AlphaButton("Normal", style: .primary) {}
    }
    .padding()
}
