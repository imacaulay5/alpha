//
//  ExpandableFAB.swift
//  alpha
//
//  Created by Claude Code on 12/18/25.
//

import SwiftUI

struct FABAction: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let color: Color
    let requiredCapability: Capability?
    let action: () -> Void

    init(icon: String, label: String, color: Color, requiredCapability: Capability? = nil, action: @escaping () -> Void) {
        self.icon = icon
        self.label = label
        self.color = color
        self.requiredCapability = requiredCapability
        self.action = action
    }
}

struct ExpandableFAB: View {
    let primaryAction: () -> Void
    let secondaryActions: [FABAction]

    @State private var isExpanded = false
    @State private var isPressing = false
    @State private var isLongPressing = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Tap outside to close overlay
            if isExpanded {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isExpanded = false
                        }
                    }
                    .ignoresSafeArea()
            }

            VStack(alignment: .trailing, spacing: 16) {
                // Secondary action buttons (appear when expanded)
                if isExpanded {
                    ForEach(secondaryActions) { action in
                        FABButton(
                            icon: action.icon,
                            label: action.label,
                            color: action.color,
                            action: {
                                action.action()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    isExpanded = false
                                }
                            }
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }

                // Primary FAB button
                Button {
                    // Only trigger primary action if it wasn't a long press
                    if !isLongPressing {
                        if isExpanded {
                            // Close menu if already expanded
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isExpanded = false
                            }
                        } else {
                            // Log time
                            primaryAction()
                        }
                    }
                    isLongPressing = false
                } label: {
                    Image(systemName: isExpanded ? "xmark" : "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Color(uiColor: .systemBackground))
                        .frame(width: 60, height: 60)
                        .background(
                            Circle()
                                .fill(Color(uiColor: .label))
                                .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
                        )
                        .scaleEffect(isPressing ? 0.9 : 1.0)
                        .rotationEffect(.degrees(isExpanded ? 45 : 0))
                }
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.5)
                        .onEnded { _ in
                            isLongPressing = true
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isExpanded.toggle()
                            }
                        }
                )
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in isPressing = true }
                        .onEnded { _ in isPressing = false }
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressing)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)
                .accessibilityLabel(isExpanded ? "Close menu" : "Log time")
                .accessibilityHint(isExpanded ? "Tap to close, or select an action" : "Tap to log time, long press for more options")
            }
        }
    }
}

struct FABButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        HStack(spacing: 12) {
            Spacer()

            // Label
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.alphaPrimaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.alphaCardBackground)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                )

            // Button
            Button(action: action) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(color)
                            .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 3)
                    )
                    .scaleEffect(isPressed ? 0.9 : 1.0)
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
    }
}

// MARK: - Preview

#Preview("Expandable FAB") {
    ZStack {
        Color.alphaGroupedBackground
            .ignoresSafeArea()

        VStack {
            Spacer()
            HStack {
                Spacer()
                ExpandableFAB(
                    primaryAction: {
                        print("Log time (long press)")
                    },
                    secondaryActions: [
                        FABAction(
                            icon: "doc.badge.plus",
                            label: "Create Invoice",
                            color: .blue,
                            action: { print("Create Invoice") }
                        ),
                        FABAction(
                            icon: "creditcard.fill",
                            label: "Quick Payment",
                            color: .orange,
                            action: { print("Quick Payment") }
                        )
                    ]
                )
                .padding(.trailing, 20)
                .padding(.bottom, 90)
            }
        }
    }
}
