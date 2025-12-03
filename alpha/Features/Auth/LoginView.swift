//
//  LoginView.swift
//  alpha
//
//  Created by Claude Code on 11/25/25.
//

import SwiftUI
import Combine

@MainActor
class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let authService = AuthService.shared

    func login(appState: AppState) async {
        // Validate inputs
        guard !email.isEmpty else {
            errorMessage = "Please enter your email"
            return
        }

        guard !password.isEmpty else {
            errorMessage = "Please enter your password"
            return
        }

        isLoading = true
        errorMessage = nil

        // Real login with backend
        do {
            print("🔐 LoginViewModel: Starting login for \(email)")
            let (user, org) = try await authService.login(
                email: email,
                password: password
            )
            print("✅ LoginViewModel: Login successful, user: \(user.name)")
            appState.login(user: user, organization: org)
            print("✅ LoginViewModel: AppState updated, isAuthenticated: \(appState.isAuthenticated)")
        } catch {
            print("❌ LoginViewModel: Login failed with error: \(error)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
        print("🔐 LoginViewModel: Login complete, isLoading: \(isLoading)")
    }
}

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = LoginViewModel()

    var body: some View {
        ZStack {
            Color.alphaBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Logo / Header
                    VStack(spacing: 12) {
                        Image(systemName: "timer.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.alphaPrimary)

                        Text("Alpha")
                            .font(.alphaDisplayLarge)
                            .foregroundColor(.alphaPrimaryText)

                        Text("Contractor Time Tracking")
                            .font(.alphaBody)
                            .foregroundColor(.alphaSecondaryText)
                    }
                    .padding(.top, 60)

                    // Login Form
                    VStack(spacing: 20) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.alphaLabel)
                                .foregroundColor(.alphaSecondaryText)

                            TextField("you@example.com", text: $viewModel.email)
                                .textFieldStyle(.plain)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .padding()
                                .background(Color.alphaCardBackground)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.alphaDivider, lineWidth: 1)
                                )
                        }

                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.alphaLabel)
                                .foregroundColor(.alphaSecondaryText)

                            SecureField("Enter your password", text: $viewModel.password)
                                .textFieldStyle(.plain)
                                .textContentType(.password)
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

                        // Login Button
                        AlphaButton(
                            "Sign In",
                            style: .primary,
                            size: .large,
                            isLoading: viewModel.isLoading,
                            isDisabled: viewModel.email.isEmpty || viewModel.password.isEmpty
                        ) {
                            Task {
                                await viewModel.login(appState: appState)
                            }
                        }
                        .padding(.top, 16)

                        // Forgot Password
                        Button(action: {
                            // TODO: Implement forgot password
                        }) {
                            Text("Forgot Password?")
                                .font(.alphaBodySmall)
                                .foregroundColor(.alphaPrimary)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)

                    // Sign Up Link
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .font(.alphaBodySmall)
                            .foregroundColor(.alphaSecondaryText)

                        Button(action: {
                            // TODO: Implement sign up
                        }) {
                            Text("Sign Up")
                                .font(.alphaBodySmall)
                                .fontWeight(.semibold)
                                .foregroundColor(.alphaPrimary)
                        }
                    }
                    .padding(.top, 32)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Login View") {
    LoginView()
        .environmentObject({
            let state = AppState()
            state.isAuthenticated = false
            return state
        }())
}

#Preview("Login View - With Error") {
    LoginView()
        .environmentObject({
            let state = AppState()
            state.isAuthenticated = false
            return state
        }())
        .onAppear {
            // Simulate error state
        }
}
