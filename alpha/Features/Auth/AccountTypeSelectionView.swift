//
//  AccountTypeSelectionView.swift
//  alpha
//
//  Created by Claude Code on 12/29/24.
//

import SwiftUI
import Combine

struct AccountTypeSelectionView: View {
    let email: String
    let userName: String

    @StateObject private var viewModel = AccountTypeSelectionViewModel()
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Text("Welcome, \(userName.components(separatedBy: " ").first ?? userName)!")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("What best describes you?")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 60)

                // Account type cards
                VStack(spacing: 16) {
                    ForEach(AccountType.allCases, id: \.self) { accountType in
                        AccountTypeCard(
                            accountType: accountType,
                            isSelected: viewModel.selectedType == accountType
                        ) {
                            viewModel.selectType(accountType)
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Continue button
                Button(action: {
                    viewModel.proceed(email: email, userName: userName)
                }) {
                    HStack {
                        Text("Continue")
                        Image(systemName: "arrow.right")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.selectedType != nil ? Color.accentColor : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(viewModel.selectedType == nil)
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
        .fullScreenCover(isPresented: $viewModel.navigateToVerification) {
            EmailVerificationView(email: email, userName: userName)
                .environmentObject(appState)
        }
    }
}

// MARK: - Account Type Card

struct AccountTypeCard: View {
    let accountType: AccountType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: accountType.icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? .white : .accentColor)
                    .frame(width: 60, height: 60)
                    .background(isSelected ? Color.accentColor : Color.accentColor.opacity(0.1))
                    .cornerRadius(12)

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(accountType.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(accountType.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.accentColor)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: isSelected ? Color.accentColor.opacity(0.3) : Color.black.opacity(0.1),
                            radius: isSelected ? 8 : 4,
                            x: 0,
                            y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - View Model

@MainActor
class AccountTypeSelectionViewModel: ObservableObject {
    @Published var selectedType: AccountType?
    @Published var navigateToVerification = false

    func selectType(_ type: AccountType) {
        selectedType = type
    }

    func proceed(email: String, userName: String) {
        guard let selectedType = selectedType else { return }

        // Store the selected account type for use after email verification
        UserDefaults.standard.set(selectedType.rawValue, forKey: "pendingAccountType")

        print("✅ AccountTypeSelection: User selected \(selectedType.displayName)")
        print("💾 AccountTypeSelection: Stored in UserDefaults")

        // Navigate to email verification
        navigateToVerification = true
    }
}

// MARK: - Preview

#Preview {
    AccountTypeSelectionView(email: "test@example.com", userName: "John Doe")
        .environmentObject(AppState())
}
