//
//  ProjectsListView.swift
//  alpha
//
//  Created by Claude Code on 1/30/26.
//

import SwiftUI
import Combine

// MARK: - ViewModel

@MainActor
class ProjectsViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var showActiveOnly = true
    @Published var selectedClientId: String?

    // Summary stats
    @Published var activeProjectsCount = 0
    @Published var totalBudget: Double = 0
    @Published var hoursThisMonth: Double = 0

    private let projectRepository = ProjectRepository()

    var filteredProjects: [Project] {
        var result = projects

        // Filter by active status
        if showActiveOnly {
            result = result.filter { $0.isActive == true }
        }

        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { project in
                project.name.localizedCaseInsensitiveContains(searchText) ||
                (project.client?.name.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // Filter by client
        if let clientId = selectedClientId {
            result = result.filter { $0.clientId == clientId }
        }

        return result
    }

    // MARK: - Public Methods

    func loadProjects() async {
        isLoading = true
        errorMessage = nil

        do {
            projects = try await projectRepository.fetchProjects()
            updateSummaryStats()
        } catch {
            errorMessage = "Failed to load projects: \(error.localizedDescription)"
            projects = []
        }

        isLoading = false
    }

    func deleteProject(_ projectId: String) async {
        do {
            try await projectRepository.deleteProject(id: projectId)
            await loadProjects()
        } catch {
            errorMessage = "Failed to delete project: \(error.localizedDescription)"
        }
    }

    func archiveProject(_ projectId: String) async {
        do {
            _ = try await projectRepository.archiveProject(id: projectId)
            await loadProjects()
        } catch {
            errorMessage = "Failed to archive project: \(error.localizedDescription)"
        }
    }

    // MARK: - Private Methods

    private func updateSummaryStats() {
        activeProjectsCount = projects.filter { $0.isActive == true }.count
        totalBudget = projects.compactMap { $0.budget }.reduce(0, +)
        hoursThisMonth = 0
    }
}

// MARK: - ProjectsListView

struct ProjectsListView: View {
    @StateObject private var viewModel = ProjectsViewModel()
    @State private var showingAddProject = false
    @State private var showingSortOptions = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Projects List
                    if viewModel.isLoading {
                        ProgressView()
                            .padding(.top, 60)
                    } else if viewModel.filteredProjects.isEmpty {
                        emptyState
                    } else {
                        projectsList
                    }
                }
            }
            .background(Color(uiColor: .systemBackground))
            .searchable(text: $viewModel.searchText, prompt: "Search projects")
            .navigationTitle("Projects")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button(action: { showingSortOptions = true }) {
                            Image(systemName: "line.3.horizontal.decrease")
                                .font(.system(size: 17, weight: .medium))
                        }

                        Menu {
                            Button(action: {}) {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button(action: {}) {
                                Label("Select", systemImage: "checkmark.circle")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 17, weight: .medium))
                        }
                    }
                }
            }
            .refreshable {
                await viewModel.loadProjects()
            }
            .task {
                await viewModel.loadProjects()
            }
            .sheet(isPresented: $showingAddProject) {
                ProjectFormSheet(isPresented: $showingAddProject, onSave: {
                    Task {
                        await viewModel.loadProjects()
                    }
                })
            }
            .confirmationDialog("Sort By", isPresented: $showingSortOptions) {
                Button("Name") { }
                Button("Date Created") { }
                Button("Client") { }
                Button("Cancel", role: .cancel) { }
            }
        }
    }

    // MARK: - Projects List

    private var projectsList: some View {
        LazyVStack(spacing: 0) {
            ForEach(viewModel.filteredProjects) { project in
                NavigationLink(destination: ProjectDetailView(project: project)) {
                    ProjectListRow(project: project)
                }
                .buttonStyle(.plain)

                if project.id != viewModel.filteredProjects.last?.id {
                    Divider()
                        .padding(.leading, 76)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No projects yet")
                .font(.headline)
                .foregroundColor(.primary)

            Text("Tap + to create your first project")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Project List Row

struct ProjectListRow: View {
    let project: Project

    var body: some View {
        HStack(spacing: 16) {
            // Project Color Thumbnail
            RoundedRectangle(cornerRadius: 8)
                .fill(projectColor)
                .frame(width: 56, height: 56)
                .overlay {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.9))
                }

            // Project Name
            VStack(alignment: .leading, spacing: 2) {
                Text(project.name)
                    .font(.system(size: 17))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                if let client = project.client {
                    Text(client.name)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(uiColor: .tertiaryLabel))
        }
        .padding(.vertical, 10)
    }

    private var projectColor: Color {
        guard let hexColor = project.color else {
            return .blue
        }
        return Color(hex: hexColor)
    }
}

// MARK: - Preview

#Preview("Projects List") {
    ProjectsListView()
}
