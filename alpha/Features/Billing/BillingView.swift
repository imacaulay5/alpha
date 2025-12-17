//
//  BillingView.swift
//  alpha
//
//  Created by Claude Code on 12/16/25.
//

import SwiftUI

struct BillingView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Placeholder content for Phase 1
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.alphaSecondaryText)

                        Text("Billing")
                            .font(.alphaHeadline)
                            .foregroundColor(.alphaPrimaryText)

                        Text("Invoices and billing overview coming soon")
                            .font(.alphaBody)
                            .foregroundColor(.alphaSecondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color.alphaBackground)
            .navigationTitle("Billing")
        }
    }
}

// MARK: - Preview

#Preview("Billing View") {
    BillingView()
}
