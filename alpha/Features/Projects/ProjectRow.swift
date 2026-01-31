//
//  ProjectRow.swift
//  alpha
//
//  Created by Claude Code on 1/30/26.
//

import SwiftUI

struct ProjectRow: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Color indicator
                RoundedRectangle(cornerRadius: 4)
                    .fill(projectColor)
                    .frame(width: 4, height: 48)

                VStack(alignment: .leading, spacing: 4) {
                    Text(project.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.alphaPrimaryText)

                    if let client = project.client {
                        Text(client.name)
                            .font(.system(size: 14))
                            .foregroundColor(.alphaSecondaryText)
                    }
                }

                Spacer()

                // Status indicator
                if project.isActive == true {
                    Text("Active")
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.alphaSuccess.opacity(0.1))
                        .foregroundColor(.alphaSuccess)
                        .cornerRadius(4)
                } else {
                    Text("Archived")
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.alphaSecondaryText.opacity(0.1))
                        .foregroundColor(.alphaSecondaryText)
                        .cornerRadius(4)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.alphaSecondaryText)
            }

            Divider()

            // Project details
            HStack(spacing: 16) {
                // Billing model
                HStack(spacing: 6) {
                    Image(systemName: billingModelIcon)
                        .font(.system(size: 12))
                        .foregroundColor(.alphaSecondaryText)

                    Text(project.billingModel.displayName)
                        .font(.system(size: 13))
                        .foregroundColor(.alphaSecondaryText)
                }

                Spacer()

                // Rate
                if project.billingModel != .notBillable {
                    Text(project.displayRate)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.alphaPrimaryText)
                }

                // Budget indicator
                if let budget = project.budget, budget > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.pie.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.alphaInfo)

                        Text(formatCurrency(budget))
                            .font(.system(size: 13))
                            .foregroundColor(.alphaSecondaryText)
                    }
                }
            }
        }
        .padding()
        .background(Color.alphaCardBackground)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    // MARK: - Computed Properties

    private var projectColor: Color {
        guard let hexColor = project.color else {
            return .alphaInfo
        }
        return Color(hex: hexColor)
    }

    private var billingModelIcon: String {
        switch project.billingModel {
        case .hourly:
            return "clock.fill"
        case .fixed:
            return "dollarsign.circle.fill"
        case .retainer:
            return "calendar.badge.clock"
        case .milestone:
            return "flag.fill"
        case .taskBased:
            return "checklist"
        case .notBillable:
            return "xmark.circle.fill"
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }
}

// MARK: - Preview

#Preview("Project Row - Active") {
    ProjectRow(project: .preview)
        .padding()
}

#Preview("Project Row - Fixed Price") {
    ProjectRow(project: .previewFixed)
        .padding()
}
