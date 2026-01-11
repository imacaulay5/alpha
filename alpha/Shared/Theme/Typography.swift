//
//  Typography.swift
//  alpha
//
//  Created by Claude Code on 11/25/25.
//

import SwiftUI

extension Font {
    // MARK: - Typography System (Aligned with Figma: 400/500/600/700 weights)
    // 400 = regular, 500 = medium, 600 = semibold, 700 = bold

    // MARK: - Display (700 bold)

    /// Extra large display text (32pt, bold)
    static let alphaDisplayLarge = Font.system(size: 32, weight: .bold)

    /// Large display text (28pt, bold)
    static let alphaDisplay = Font.system(size: 28, weight: .bold)

    // MARK: - Headline (600 semibold)

    /// Large headline (24pt, semibold)
    static let alphaHeadlineLarge = Font.system(size: 24, weight: .semibold)

    /// Standard headline (20pt, semibold)
    static let alphaHeadline = Font.system(size: 20, weight: .semibold)

    /// Small headline (18pt, semibold)
    static let alphaHeadlineSmall = Font.system(size: 18, weight: .semibold)

    // MARK: - Title (600 semibold)

    /// Large title (20pt, semibold)
    static let alphaTitleLarge = Font.system(size: 20, weight: .semibold)

    /// Standard title (18pt, semibold)
    static let alphaTitle = Font.system(size: 18, weight: .semibold)

    /// Small title (16pt, semibold)
    static let alphaTitleSmall = Font.system(size: 16, weight: .semibold)

    // MARK: - Body (400 regular, 500 medium)

    /// Large body text (17pt, regular)
    static let alphaBodyLarge = Font.system(size: 17, weight: .regular)

    /// Standard body text (16pt, regular)
    static let alphaBody = Font.system(size: 16, weight: .regular)

    /// Small body text (14pt, regular)
    static let alphaBodySmall = Font.system(size: 14, weight: .regular)

    /// Medium body text (16pt, medium) - for emphasis
    static let alphaBodyMedium = Font.system(size: 16, weight: .medium)

    // MARK: - Label

    /// Large label (14pt, medium)
    static let alphaLabelLarge = Font.system(size: 14, weight: .medium)

    /// Standard label (12pt, medium)
    static let alphaLabel = Font.system(size: 12, weight: .medium)

    /// Small label (10pt, medium)
    static let alphaLabelSmall = Font.system(size: 10, weight: .medium)

    // MARK: - Caption

    /// Standard caption (12pt, regular)
    static let alphaCaption = Font.system(size: 12, weight: .regular)

    /// Small caption (10pt, regular)
    static let alphaCaptionSmall = Font.system(size: 10, weight: .regular)

    // MARK: - Monospaced (for timer, numbers)

    /// Large monospaced (for timer display)
    static let alphaMonospacedLarge = Font.system(size: 48, weight: .bold, design: .monospaced)

    /// Standard monospaced (for amounts, numbers)
    static let alphaMonospaced = Font.system(size: 16, weight: .medium, design: .monospaced)
}

// MARK: - Text Style Modifiers

extension View {
    /// Apply display large style
    func displayLarge() -> some View {
        self.font(.alphaDisplayLarge)
    }

    /// Apply headline style
    func headline() -> some View {
        self.font(.alphaHeadline)
    }

    /// Apply title style
    func title() -> some View {
        self.font(.alphaTitle)
    }

    /// Apply body style
    func body() -> some View {
        self.font(.alphaBody)
    }

    /// Apply label style
    func label() -> some View {
        self.font(.alphaLabel)
            .foregroundColor(.alphaSecondaryText)
    }

    /// Apply caption style
    func caption() -> some View {
        self.font(.alphaCaption)
            .foregroundColor(.alphaTertiaryText)
    }
}
