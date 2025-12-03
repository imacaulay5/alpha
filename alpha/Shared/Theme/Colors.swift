//
//  Colors.swift
//  alpha
//
//  Created by Claude Code on 11/25/25.
//

import SwiftUI

extension Color {
    // MARK: - Primary Colors

    /// Primary brand color (from Assets.xcassets)
    static let alphaPrimary = Color("Primary")

    /// Secondary brand color (from Assets.xcassets)
    static let alphaSecondary = Color("Secondary")

    /// Accent color for UI elements (from Assets.xcassets)
    static let alphaAccent = Color("AccentColor")

    // MARK: - Text Colors

    /// Primary text color
    static let alphaPrimaryText = Color.primary

    /// Secondary text color (lighter, for descriptions)
    static let alphaSecondaryText = Color.secondary

    /// Tertiary text color (lightest, for hints)
    static let alphaTertiaryText = Color(uiColor: .tertiaryLabel)

    // MARK: - Background Colors

    /// Main background color
    static let alphaBackground = Color(uiColor: .systemBackground)

    /// Secondary background (for cards, surfaces)
    static let alphaCardBackground = Color(uiColor: .secondarySystemBackground)

    /// Grouped background (for list backgrounds)
    static let alphaGroupedBackground = Color(uiColor: .systemGroupedBackground)

    // MARK: - Status Colors

    /// Success color (green)
    static let alphaSuccess = Color.green

    /// Warning color (orange)
    static let alphaWarning = Color.orange

    /// Error color (red)
    static let alphaError = Color.red

    /// Info color (blue)
    static let alphaInfo = Color.blue

    // MARK: - Time Entry Status Colors

    static func timeEntryStatusColor(_ status: TimeEntryStatus) -> Color {
        switch status {
        case .draft:
            return Color.gray
        case .submitted:
            return Color.blue
        case .approved:
            return Color.green
        case .rejected:
            return Color.red
        case .invoiced:
            return Color.purple
        }
    }

    // MARK: - Expense Status Colors

    static func expenseStatusColor(_ status: ExpenseStatus) -> Color {
        switch status {
        case .draft:
            return Color.gray
        case .submitted:
            return Color.blue
        case .approved:
            return Color.green
        case .rejected:
            return Color.red
        case .reimbursed:
            return Color.purple
        }
    }

    // MARK: - Invoice Status Colors

    static func invoiceStatusColor(_ status: InvoiceStatus) -> Color {
        switch status {
        case .draft:
            return Color.gray
        case .sent:
            return Color.blue
        case .paid:
            return Color.green
        case .overdue:
            return Color.red
        case .cancelled:
            return Color.gray
        }
    }

    // MARK: - Divider

    /// Divider/separator color
    static let alphaDivider = Color(uiColor: .separator)
}

// MARK: - Helper for hex colors (if needed later)

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
