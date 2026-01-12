//
//  TaxDeadlineRow.swift
//  alpha
//
//  Created by Claude Code on 01/12/26.
//

import SwiftUI

struct TaxDeadlineRow: View {
    let deadline: TaxDeadline

    var body: some View {
        HStack(spacing: 16) {
            // Urgency indicator with countdown
            VStack {
                ZStack {
                    Circle()
                        .fill(deadline.urgency.backgroundColor)
                        .frame(width: 56, height: 56)

                    VStack(spacing: 2) {
                        Text("\(deadline.daysRemaining)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(deadline.urgency.color)

                        Text("days")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(deadline.urgency.color)
                    }
                }
            }

            // Deadline details
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(deadline.type.displayName)
                        .font(.alphaHeadline)
                        .foregroundColor(.alphaPrimaryText)

                    if deadline.status == .overdue {
                        Text("OVERDUE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .cornerRadius(4)
                    }
                }

                Text(deadline.description)
                    .font(.alphaBodySmall)
                    .foregroundColor(.alphaSecondaryText)

                HStack(spacing: 12) {
                    Label(formatDate(deadline.dueDate), systemImage: "calendar")
                        .font(.alphaCaption)
                        .foregroundColor(.alphaTertiaryText)

                    if let amount = deadline.amount {
                        Label(formatCurrency(amount), systemImage: "dollarsign.circle")
                            .font(.alphaCaption)
                            .foregroundColor(.alphaTertiaryText)
                    }
                }
            }

            Spacer()

            // Action button
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.alphaSecondaryText)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}
