//
//  AlphaCard.swift
//  alpha
//
//  Created by Claude Code on 11/25/25.
//

import SwiftUI

struct AlphaCard<Content: View>: View {
    let content: Content
    let padding: CGFloat
    let cornerRadius: CGFloat

    init(
        padding: CGFloat = 16,
        cornerRadius: CGFloat = 12,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(Color.alphaCardBackground)
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Convenience Modifiers

extension View {
    /// Wrap view in an AlphaCard
    func alphaCard(padding: CGFloat = 16, cornerRadius: CGFloat = 12) -> some View {
        AlphaCard(padding: padding, cornerRadius: cornerRadius) {
            self
        }
    }
}

// MARK: - Preview

#Preview("Card Examples") {
    ScrollView {
        VStack(spacing: 16) {
            // Simple card
            AlphaCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Card Title")
                        .font(.alphaHeadline)
                    Text("This is some content inside a card")
                        .font(.alphaBody)
                        .foregroundColor(.alphaSecondaryText)
                }
            }

            // Card with metric
            AlphaCard {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hours Today")
                        .font(.alphaLabel)
                        .foregroundColor(.alphaSecondaryText)
                    Text("7.5")
                        .font(.alphaDisplayLarge)
                        .foregroundColor(.alphaPrimary)
                }
            }

            // Card using modifier
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(.alphaPrimary)
                    Text("Time Entry")
                        .font(.alphaTitle)
                }

                Text("Working on mobile app")
                    .font(.alphaBodySmall)
                    .foregroundColor(.alphaSecondaryText)

                HStack {
                    Text("2h 30m")
                        .font(.alphaBody)
                    Spacer()
                    Text("$375.00")
                        .font(.alphaBody)
                        .foregroundColor(.alphaSuccess)
                }
            }
            .alphaCard()

            // List of items in card
            AlphaCard {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(0..<3, id: \.self) { index in
                        HStack {
                            Circle()
                                .fill(Color.alphaPrimary)
                                .frame(width: 8, height: 8)
                            Text("Item \(index + 1)")
                                .font(.alphaBody)
                            Spacer()
                            Text("$\(100 * (index + 1))")
                                .font(.alphaBodySmall)
                                .foregroundColor(.alphaSecondaryText)
                        }

                        if index < 2 {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding()
    }
    .background(Color.alphaGroupedBackground)
}
