//
//  OnboardingView.swift
//  alpha
//
//  Created by Claude Code on 12/18/24.
//

import SwiftUI
import Combine

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var companyName = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let authService = AuthService.shared
    let userName: String

    init(userName: String) {
        self.userName = userName
    }

    func setupOrganization(appState: AppState) async {
        // Validate inputs
        guard !companyName.isEmpty else {
            errorMessage = "Please enter your company name"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            print("🏢 OnboardingViewModel: Setting up organization")
            let (user, organization) = try await authService.setupOrganization(
                name: userName,
                companyName: companyName
            )
            print("✅ OnboardingViewModel: Organization setup successful")
            appState.login(user: user, organization: organization)
        } catch {
            print("❌ OnboardingViewModel: Organization setup failed: \(error)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    let userName: String
    @StateObject private var viewModel: OnboardingViewModel

    init(userName: String) {
        self.userName = userName
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(userName: userName))
    }

    var body: some View {
        ZStack {
            Color.alphaBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "building.2.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.accentColor)

                        Text("Welcome, \(userName.split(separator: " ").first ?? "")! 👋")
                            .font(.alphaDisplayLarge)
                            .foregroundColor(.alphaPrimaryText)

                        Text("Let's set up your company workspace")
                            .font(.alphaBody)
                            .foregroundColor(.alphaSecondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 60)

                    // Onboarding Form
                    VStack(spacing: 20) {
                        // Company Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Company Name")
                                .font(.alphaLabel)
                                .foregroundColor(.alphaSecondaryText)

                            TextField("Acme Inc.", text: $viewModel.companyName)
                                .textFieldStyle(.plain)
                                .textContentType(.organizationName)
                                .padding()
                                .background(Color.alphaCardBackground)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.alphaDivider, lineWidth: 1)
                                )
                        }

                        // Error Message
                        if let errorMessage = viewModel.errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.alphaError)
                                Text(errorMessage)
                                    .font(.alphaBodySmall)
                                    .foregroundColor(.alphaError)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.alphaError.opacity(0.1))
                            .cornerRadius(8)
                        }

                        // Continue Button
                        AlphaButton(
                            "Get Started",
                            style: .primary,
                            size: .large,
                            isLoading: viewModel.isLoading,
                            isDisabled: !isFormValid
                        ) {
                            Task {
                                await viewModel.setupOrganization(appState: appState)
                            }
                        }
                        .padding(.top, 16)
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }
            }
        }
        .interactiveDismissDisabled()
    }

    private var isFormValid: Bool {
        !viewModel.companyName.isEmpty
    }
}

// MARK: - Preview

#Preview("Onboarding View") {
    OnboardingView(userName: "John Doe")
        .environmentObject({
            let state = AppState()
            state.isAuthenticated = false
            return state
        }())
}
