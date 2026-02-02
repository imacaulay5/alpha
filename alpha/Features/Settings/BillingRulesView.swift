//
//  BillingRulesView.swift
//  alpha
//
//  Created by Claude Code on 12/16/25.
//

import SwiftUI
import Combine

// MARK: - ViewModel

@MainActor
class BillingRulesViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""

    private let projectRepository = ProjectRepository()

    var activeProjects: [Project] {
        projects.filter { $0.isActive == true }
    }

    var inactiveProjects: [Project] {
        projects.filter { $0.isActive == false }
    }

    var filteredActiveProjects: [Project] {
        if searchText.isEmpty {
            return activeProjects
        }
        return activeProjects.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var filteredInactiveProjects: [Project] {
        if searchText.isEmpty {
            return inactiveProjects
        }
        return inactiveProjects.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    func loadProjects() async {
        isLoading = true
        errorMessage = nil

        do {
            // Get all projects (not just active ones)
            projects = try await projectRepository.fetchProjects()
        } catch {
            errorMessage = "Failed to load projects: \(error.localizedDescription)"
            projects = []
        }

        isLoading = false
    }
}

// MARK: - BillingRulesView

struct BillingRulesView: View {
    @StateObject private var viewModel = BillingRulesViewModel()

    var body: some View {
        List {
            // Active Projects Section
            if !viewModel.filteredActiveProjects.isEmpty {
                Section {
                    ForEach(viewModel.filteredActiveProjects) { project in
                        NavigationLink {
                            ProjectBillingEditView(project: project) {
                                Task {
                                    await viewModel.loadProjects()
                                }
                            }
                        } label: {
                            ProjectBillingCard(project: project)
                        }
                    }
                } header: {
                    Text("Active Projects")
                }
            }

            // Inactive Projects Section
            if !viewModel.filteredInactiveProjects.isEmpty {
                Section {
                    ForEach(viewModel.filteredInactiveProjects) { project in
                        NavigationLink {
                            ProjectBillingEditView(project: project) {
                                Task {
                                    await viewModel.loadProjects()
                                }
                            }
                        } label: {
                            ProjectBillingCard(project: project)
                        }
                    }
                } header: {
                    Text("Inactive Projects")
                }
            }

            // Empty State
            if viewModel.projects.isEmpty && !viewModel.isLoading {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "folder")
                            .font(.system(size: 48))
                            .foregroundColor(.alphaSecondaryText)

                        Text("No projects yet")
                            .font(.alphaBody)
                            .foregroundColor(.alphaSecondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 48)
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search projects")
        .navigationTitle("Billing Rules")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.loadProjects()
        }
        .task {
            await viewModel.loadProjects()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }
}

// MARK: - ProjectBillingCard

struct ProjectBillingCard: View {
    let project: Project

    var body: some View {
        HStack(spacing: 12) {
            // Project color indicator
            Circle()
                .fill(Color(hex: project.color ?? "#007AFF"))
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.alphaPrimaryText)

                HStack(spacing: 8) {
                    // Client name
                    if let client = project.client {
                        Text(client.name)
                            .font(.system(size: 14))
                            .foregroundColor(.alphaSecondaryText)
                    }

                    // Billing model badge
                    Text(project.billingModel.displayName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue)
                        .cornerRadius(4)
                }
            }

            Spacer()

            // Rate display
            if project.rate != nil {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(project.displayRate)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.alphaPrimaryText)

                    if let budget = project.budget, budget > 0 {
                        Text(String(format: "Budget: $%.0f", budget))
                            .font(.system(size: 11))
                            .foregroundColor(.alphaSecondaryText)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview("Billing Rules View") {
    NavigationStack {
        BillingRulesView()
    }
}
