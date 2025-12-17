//
//  QuickActionCard.swift
//  alpha
//
//  Created by Claude Code on 12/17/25.
//

import SwiftUI

struct QuickActionCard: View {
    let title: String
    let description: String
    let icon: String
    let backgroundColor: Color
    let iconColor: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Icon with colored circle background
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(iconColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.alphaBody)
                        .fontWeight(.semibold)
                        .foregroundColor(.alphaPrimaryText)

                    Text(description)
                        .font(.alphaCaption)
                        .foregroundColor(.alphaSecondaryText)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(backgroundColor)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .accessibilityLabel(title)
        .accessibilityHint(description)
    }
}

// MARK: - Preview

#Preview("Quick Action Cards") {
    ScrollView {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            QuickActionCard(
                title: "Create Invoice",
                description: "Generate new invoice",
                icon: "doc.badge.plus",
                backgroundColor: Color.blue.opacity(0.1),
                iconColor: .blue
            ) {
                print("Create Invoice tapped")
            }

            QuickActionCard(
                title: "Quick Bill",
                description: "Record expense quickly",
                icon: "receipt.fill",
                backgroundColor: Color.green.opacity(0.1),
                iconColor: .green
            ) {
                print("Quick Bill tapped")
            }

            QuickActionCard(
                title: "GST Calculator",
                description: "Calculate GST amount",
                icon: "calculator.fill",
                backgroundColor: Color.purple.opacity(0.1),
                iconColor: .purple
            ) {
                print("GST Calculator tapped")
            }

            QuickActionCard(
                title: "Quick Payment",
                description: "Record payment",
                icon: "creditcard.fill",
                backgroundColor: Color.orange.opacity(0.1),
                iconColor: .orange
            ) {
                print("Quick Payment tapped")
            }
        }
        .padding()
    }
    .background(Color.alphaGroupedBackground)
}
