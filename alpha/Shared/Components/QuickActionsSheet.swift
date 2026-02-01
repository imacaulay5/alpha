//
//  QuickActionsSheet.swift
//  alpha
//
//  Created by Claude Code on 1/31/26.
//

import SwiftUI

struct QuickAction: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
}

struct QuickActionsSheet: View {
    @Binding var isPresented: Bool
    let actions: [QuickAction]

    var body: some View {
        NavigationStack {
            List {
                ForEach(actions) { action in
                    Button(action: {
                        isPresented = false
                        action.action()
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: action.icon)
                                .font(.system(size: 20))
                                .foregroundColor(action.color)
                                .frame(width: 28)

                            Text(action.label)
                                .font(.system(size: 17))
                                .foregroundColor(action.color)

                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Quick Actions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#Preview("Quick Actions Sheet") {
    QuickActionsSheet(
        isPresented: .constant(true),
        actions: [
            QuickAction(icon: "clock.fill", label: "Log Time", color: .purple, action: {}),
            QuickAction(icon: "doc.badge.plus", label: "Create Invoice", color: .blue, action: {}),
            QuickAction(icon: "folder.badge.plus", label: "New Project", color: .cyan, action: {}),
            QuickAction(icon: "doc.text.fill", label: "Quick Bill", color: .green, action: {}),
            QuickAction(icon: "creditcard.fill", label: "Record Payment", color: .orange, action: {})
        ]
    )
}
