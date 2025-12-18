//
//  ActivityItemRow.swift
//  alpha
//
//  Created by Claude Code on 12/17/25.
//

import SwiftUI

// MARK: - Activity Item Model

struct ActivityItem: Codable, Identifiable, Sendable {
    let id: Int
    let type: String
    let title: String
    let timestamp: Date
    let icon: String
}

// MARK: - Activity Item Row

struct ActivityItemRow: View {
    let activity: ActivityItem

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: activity.icon)
                .font(.body)
                .foregroundColor(.alphaPrimary)
                .frame(width: 32, height: 32)
                .background(Color.alphaPrimary.opacity(0.1))
                .cornerRadius(8)

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.alphaBody)
                    .foregroundColor(.alphaPrimaryText)

                Text(formatTimestamp(activity.timestamp))
                    .font(.alphaCaption)
                    .foregroundColor(.alphaSecondaryText)
            }

            Spacer()
        }
    }

    private func formatTimestamp(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview("Activity Item Rows") {
    let sampleActivities = [
        ActivityItem(
            id: 1,
            type: "invoice_paid",
            title: "Invoice #INV-001 paid",
            timestamp: Date().addingTimeInterval(-3600),
            icon: "checkmark.circle.fill"
        ),
        ActivityItem(
            id: 2,
            type: "invoice_created",
            title: "Invoice #INV-002 created",
            timestamp: Date().addingTimeInterval(-7200),
            icon: "doc.fill"
        ),
        ActivityItem(
            id: 3,
            type: "expense_submitted",
            title: "Office Supplies: $125.50",
            timestamp: Date().addingTimeInterval(-86400),
            icon: "dollarsign.circle.fill"
        ),
        ActivityItem(
            id: 4,
            type: "time_approved",
            title: "Time entry approved (8.5h)",
            timestamp: Date().addingTimeInterval(-172800),
            icon: "clock.fill"
        )
    ]

    ScrollView {
        VStack(spacing: 0) {
            ForEach(sampleActivities) { activity in
                ActivityItemRow(activity: activity)
                    .padding(.vertical, 12)
                    .padding(.horizontal)

                if activity.id != sampleActivities.last?.id {
                    Divider()
                        .padding(.leading, 56)
                }
            }
        }
        .background(Color.alphaCardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding()
    }
    .background(Color.alphaGroupedBackground)
}
