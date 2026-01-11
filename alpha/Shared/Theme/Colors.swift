//
//  Colors.swift
//  alpha
//
//  Created by Claude Code on 11/25/25.
//

import SwiftUI

extension Color {
    // MARK: - Primary Brand Colors (from Figma template)

    /// Deep black-purple primary color (#030213)
    static let alphaPrimary = Color(hex: "030213")

    /// Lighter variant for primary elements
    static let alphaPrimaryLight = Color(hex: "1A1B2E")

    /// Light lavender secondary color
    static let alphaSecondary = Color(hex: "F3F3F5")

    /// Accent color for UI elements
    static let alphaAccent = Color(hex: "E9EBEF")

    // MARK: - Status Colors (Figma OKLCH palette)

    /// Success green - for approved, paid, positive states
    static let alphaSuccess = Color(hex: "10B981")

    /// Warning amber - for pending, overdue states
    static let alphaWarning = Color(hex: "F59E0B")

    /// Error red - for rejected, failed states
    static let alphaError = Color(hex: "EF4444")

    /// Info blue - for informational states
    static let alphaInfo = Color(hex: "3B82F6")

    // MARK: - Semantic State Colors

    static let alphaDraft = Color(hex: "6B7280")        // Gray
    static let alphaPending = Color(hex: "6366F1")      // Indigo
    static let alphaApproved = Color(hex: "10B981")     // Green
    static let alphaRejected = Color(hex: "EF4444")     // Red
    static let alphaPaid = Color(hex: "8B5CF6")         // Purple
    static let alphaOverdue = Color(hex: "DC2626")      // Dark red
    static let alphaInvoiced = Color(hex: "8B5CF6")     // Purple

    // MARK: - Text Colors

    /// Primary text color
    static let alphaPrimaryText = Color.primary

    /// Secondary text color (lighter, for descriptions)
    static let alphaSecondaryText = Color.secondary

    /// Tertiary text color (lightest, for hints)
    static let alphaTertiaryText = Color(uiColor: .tertiaryLabel)

    /// Placeholder text color
    static let alphaPlaceholderText = Color(uiColor: .placeholderText)

    // MARK: - Background Colors (Dark mode aware)

    /// Main background color
    static let alphaBackground = Color(uiColor: .systemBackground)

    /// Secondary background (for cards, surfaces)
    static let alphaCardBackground = Color(uiColor: .secondarySystemBackground)

    /// Grouped background (for list backgrounds)
    static let alphaGroupedBackground = Color(uiColor: .systemGroupedBackground)

    /// Input background
    static let alphaInputBackground = Color(hex: "F3F3F5")

    // MARK: - Border & Divider

    /// Border color
    static let alphaBorder = Color(uiColor: .separator)

    /// Divider/separator color
    static let alphaDivider = Color(uiColor: .separator)

    // MARK: - Chart Colors (from Figma)

    static let alphaChart1 = Color(hex: "F97316")  // Orange
    static let alphaChart2 = Color(hex: "3B82F6")  // Blue
    static let alphaChart3 = Color(hex: "8B5CF6")  // Purple
    static let alphaChart4 = Color(hex: "FBBF24")  // Yellow
    static let alphaChart5 = Color(hex: "F59E0B")  // Amber

    // MARK: - Status-Aware Color Functions

    static func timeEntryStatusColor(_ status: TimeEntryStatus) -> Color {
        switch status {
        case .draft:
            return .alphaDraft
        case .submitted:
            return .alphaPending
        case .approved:
            return .alphaApproved
        case .rejected:
            return .alphaRejected
        case .invoiced:
            return .alphaInvoiced
        }
    }

    static func expenseStatusColor(_ status: ExpenseStatus) -> Color {
        switch status {
        case .draft:
            return .alphaDraft
        case .submitted:
            return .alphaPending
        case .approved:
            return .alphaApproved
        case .rejected:
            return .alphaRejected
        case .reimbursed:
            return .alphaPaid
        }
    }

    static func invoiceStatusColor(_ status: InvoiceStatus) -> Color {
        switch status {
        case .draft:
            return .alphaDraft
        case .sent:
            return .alphaPending
        case .paid:
            return .alphaPaid
        case .overdue:
            return .alphaOverdue
        case .cancelled:
            return .alphaRejected
        }
    }
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
