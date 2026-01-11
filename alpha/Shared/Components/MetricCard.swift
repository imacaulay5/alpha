//
//  MetricCard.swift
//  alpha
//
//  Created by Claude Code on 12/18/25.
//

import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let trend: TrendDirection?
    let changePercentage: Double?
    let icon: String
    let backgroundColor: Color
    let iconColor: Color

    init(
        title: String,
        value: String,
        trend: TrendDirection? = nil,
        changePercentage: Double? = nil,
        icon: String,
        backgroundColor: Color,
        iconColor: Color
    ) {
        self.title = title
        self.value = value
        self.trend = trend
        self.changePercentage = changePercentage
        self.icon = icon
        self.backgroundColor = backgroundColor
        self.iconColor = iconColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Colored badge with icon and title
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundColor(iconColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(backgroundColor)
            .cornerRadius(6)

            Spacer()

            // Large value
            Text(value)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.alphaPrimaryText)
                .lineLimit(1)

            // Trend indicator at bottom (only if trend is provided)
            if let trend = trend, let changePercentage = changePercentage {
                HStack(spacing: 4) {
                    Image(systemName: trend.icon)
                        .font(.system(size: 12))
                    Text(formatPercentage(changePercentage))
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(trend.color)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
        .padding(16)
        .background(Color.alphaCardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    private func formatPercentage(_ value: Double) -> String {
        String(format: "%.1f%%", abs(value))
    }
}

// MARK: - Preview

#Preview("Metric Cards") {
    ScrollView {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            MetricCard(
                title: "Total Revenue",
                value: "$12.5K",
                trend: .up,
                changePercentage: 12.5,
                icon: "dollarsign.circle.fill",
                backgroundColor: Color.green.opacity(0.1),
                iconColor: .green
            )

            MetricCard(
                title: "Outstanding Revenue",
                value: "$3.2K",
                trend: .down,
                changePercentage: -5.2,
                icon: "exclamationmark.circle.fill",
                backgroundColor: Color.orange.opacity(0.1),
                iconColor: .orange
            )

            MetricCard(
                title: "Billable Hours",
                value: "42.5",
                trend: .up,
                changePercentage: 8.3,
                icon: "clock.fill",
                backgroundColor: Color.purple.opacity(0.1),
                iconColor: .purple
            )

            MetricCard(
                title: "Pending Invoices",
                value: "7",
                trend: .neutral,
                changePercentage: 0.0,
                icon: "doc.text.fill",
                backgroundColor: Color.blue.opacity(0.1),
                iconColor: .blue
            )
        }
        .padding()
    }
    .background(Color.alphaGroupedBackground)
}
