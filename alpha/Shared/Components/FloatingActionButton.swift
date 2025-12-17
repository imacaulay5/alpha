//
//  FloatingActionButton.swift
//  alpha
//
//  Created by Claude Code on 12/16/25.
//

import SwiftUI

struct FloatingActionButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(Color.alphaPrimary)
                        .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
                )
        }
        .accessibilityLabel("Add Time Entry")
        .accessibilityHint("Double tap to log a new task or time entry")
    }
}

// MARK: - Preview

#Preview("Floating Action Button") {
    ZStack {
        Color.alphaBackground
            .ignoresSafeArea()

        VStack {
            Spacer()
            HStack {
                Spacer()
                FloatingActionButton {
                    print("FAB tapped")
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
    }
}

#Preview("FAB with Tab Bar") {
    ZStack {
        TabView {
            Text("Home")
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            Text("Tasks")
                .tabItem {
                    Label("Tasks", systemImage: "list.bullet.clipboard")
                }
        }
        .tint(.alphaPrimary)

        VStack {
            Spacer()
            HStack {
                Spacer()
                FloatingActionButton {
                    print("FAB tapped")
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
    }
}
