//
//  StatisticCard.swift
//  alpha
//
//  Created by Claude Code on 12/17/25.
//

import SwiftUI

// MARK: - Trend Direction

enum TrendDirection: String, Codable {
    case up = "UP"
    case down = "DOWN"
    case neutral = "NEUTRAL"

    var icon: String {
        switch self {
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .neutral: return "minus"
        }
    }

    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .neutral: return .gray
        }
    }
}

// MARK: - Statistic Card

struct StatisticCard: View {
    let title: String
    let value: String
    let trend: TrendDirection
    let changePercentage: Double
    let icon: String
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon in top-left
            HStack {
                Image(systemName: icon)
                    .foregroundColor(accentColor)
                    .font(.title3)
                Spacer()
            }

            // Large value
            Text(value)
                .font(.alphaDisplayLarge)
                .foregroundColor(.alphaPrimaryText)

            // Title and trend
            HStack {
                Text(title)
                    .font(.alphaLabel)
                    .foregroundColor(.alphaSecondaryText)

                Spacer()

                // Trend indicator
                HStack(spacing: 4) {
                    Image(systemName: trend.icon)
                        .font(.caption)
                    Text(formatPercentage(changePercentage))
                        .font(.alphaCaption)
                }
                .foregroundColor(trend.color)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.alphaCardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value), \(trend == .up ? "up" : trend == .down ? "down" : "neutral") \(formatPercentage(changePercentage))")
    }

    private func formatPercentage(_ value: Double) -> String {
        String(format: "%.1f%%", abs(value))
    }
}

// MARK: - Preview

#Preview("Statistic Cards") {
    ScrollView {
        VStack(spacing: 16) {
            // Revenue card
            StatisticCard(
                title: "Total Revenue",
                value: "$12.5K",
                trend: .up,
                changePercentage: 12.5,
                icon: "dollarsign.circle.fill",
                accentColor: .green
            )

            // Outstanding revenue card
            StatisticCard(
                title: "Outstanding Revenue",
                value: "$3.2K",
                trend: .down,
                changePercentage: -5.2,
                icon: "exclamationmark.circle.fill",
                accentColor: .orange
            )

            // Billable hours card
            StatisticCard(
                title: "Billable Hours",
                value: "42.5",
                trend: .up,
                changePercentage: 8.3,
                icon: "clock.fill",
                accentColor: .purple
            )

            // Pending invoices card
            StatisticCard(
                title: "Pending Invoices",
                value: "7",
                trend: .neutral,
                changePercentage: 0.0,
                icon: "doc.text.fill",
                accentColor: .orange
            )
        }
        .padding()
    }
    .background(Color.alphaGroupedBackground)
}
