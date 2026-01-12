//
//  TaxFilingRow.swift
//  alpha
//
//  Created by Claude Code on 01/12/26.
//

import SwiftUI

struct TaxFilingRow: View {
    let filing: TaxFiling

    var body: some View {
        HStack(spacing: 16) {
            // Type icon with status color
            ZStack {
                Circle()
                    .fill(filing.status.color.opacity(0.1))
                    .frame(width: 56, height: 56)

                Image(systemName: filing.type.icon)
                    .font(.system(size: 24))
                    .foregroundColor(filing.status.color)
            }

            // Filing details
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(filing.type.displayName)
                        .font(.alphaHeadline)
                        .foregroundColor(.alphaPrimaryText)

                    Text(filing.status.rawValue)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(filing.status.color)
                        .cornerRadius(4)
                }

                Text("Tax Year \(filing.taxYear)")
                    .font(.alphaBodySmall)
                    .foregroundColor(.alphaSecondaryText)

                HStack(spacing: 12) {
                    Label(formatDate(filing.filingDate), systemImage: "calendar")
                        .font(.alphaCaption)
                        .foregroundColor(.alphaTertiaryText)

                    if let amount = filing.amount {
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
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}
