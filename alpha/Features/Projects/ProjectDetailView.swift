//
//  ProjectDetailView.swift
//  alpha
//
//  Created by Claude Code on 1/30/26.
//

import SwiftUI
import Combine

// MARK: - ViewModel

@MainActor
class ProjectDetailViewModel: ObservableObject {
    @Published var project: Project
    @Published var tasks: [ProjectTask] = []
    @Published var timeEntries: [TimeEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Computed stats
    @Published var totalHours: Double = 0
    @Published var totalBilled: Double = 0

    private let taskRepository = TaskRepository()
    private let timeEntryRepository = TimeEntryRepository()
    private let projectRepository = ProjectRepository()

    init(project: Project) {
        self.project = project
    }

    func loadProjectData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Load tasks
            tasks = try await taskRepository.fetchTasks(projectId: project.id)

            // Load time entries
            timeEntries = try await timeEntryRepository.fetchTimeEntries(projectId: project.id)

            calculateStats()
        } catch {
            errorMessage = "Failed to load project data: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func refreshProject() async {
        do {
            project = try await projectRepository.fetchProject(id: project.id)
        } catch {
            // Silently fail
        }
    }

    private func calculateStats() {
        totalHours = timeEntries.reduce(0) { $0 + Double($1.durationMinutes) / 60.0 }
        totalBilled = timeEntries.compactMap { entry -> Double? in
            guard let rate = entry.billableRate else { return nil }
            return Double(entry.durationMinutes) / 60.0 * rate
        }.reduce(0, +)
    }
}

// MARK: - ProjectDetailView

struct ProjectDetailView: View {
    @StateObject private var viewModel: ProjectDetailViewModel
    @State private var selectedTab = 0
    @State private var showingEditSheet = false
    @Environment(\.dismiss) private var dismiss

    init(project: Project) {
        _viewModel = StateObject(wrappedValue: ProjectDetailViewModel(project: project))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Project Header Card
                projectHeader

                // Stats Cards
                statsCards

                // Tabbed Content
                tabbedContent
            }
            .padding()
        }
        .background(Color.alphaGroupedBackground)
        .navigationTitle(viewModel.project.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingEditSheet = true }) {
                    Text("Edit")
                        .foregroundColor(.alphaInfo)
                }
            }
        }
        .refreshable {
            await viewModel.loadProjectData()
            await viewModel.refreshProject()
        }
        .task {
            await viewModel.loadProjectData()
        }
        .sheet(isPresented: $showingEditSheet) {
            ProjectFormSheet(isPresented: $showingEditSheet, project: viewModel.project, onSave: {
                Task {
                    await viewModel.refreshProject()
                }
            })
            .withAppTheme()
        }
    }

    // MARK: - Project Header

    private var projectHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                // Color indicator
                RoundedRectangle(cornerRadius: 6)
                    .fill(projectColor)
                    .frame(width: 6, height: 60)

                VStack(alignment: .leading, spacing: 4) {
                    if let client = viewModel.project.client {
                        Text(client.name)
                            .font(.system(size: 14))
                            .foregroundColor(.alphaSecondaryText)
                    }

                    Text(viewModel.project.name)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.alphaPrimaryText)

                    if let description = viewModel.project.description, !description.isEmpty {
                        Text(description)
                            .font(.system(size: 14))
                            .foregroundColor(.alphaSecondaryText)
                            .lineLimit(2)
                    }
                }

                Spacer()

                // Status badge
                statusBadge
            }

            Divider()

            // Billing info
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Billing")
                        .font(.system(size: 12))
                        .foregroundColor(.alphaSecondaryText)

                    Text(viewModel.project.billingModel.displayName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.alphaPrimaryText)
                }

                if viewModel.project.billingModel != .notBillable {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Rate")
                            .font(.system(size: 12))
                            .foregroundColor(.alphaSecondaryText)

                        Text(viewModel.project.displayRate)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.alphaPrimaryText)
                    }
                }

                if let budget = viewModel.project.budget, budget > 0 {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Budget")
                            .font(.system(size: 12))
                            .foregroundColor(.alphaSecondaryText)

                        Text(formatCurrency(budget))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.alphaPrimaryText)
                    }
                }

                Spacer()
            }
        }
        .padding()
        .background(Color.alphaCardBackground)
        .cornerRadius(12)
    }

    // MARK: - Stats Cards

    private var statsCards: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Total Hours",
                value: String(format: "%.1f", viewModel.totalHours),
                icon: "clock.fill",
                color: .alphaInfo
            )

            StatCard(
                title: "Total Billed",
                value: formatCurrency(viewModel.totalBilled),
                icon: "dollarsign.circle.fill",
                color: .alphaSuccess
            )

            StatCard(
                title: "Tasks",
                value: "\(viewModel.tasks.count)",
                icon: "checklist",
                color: .alphaWarning
            )
        }
    }

    // MARK: - Tabbed Content

    private var tabbedContent: some View {
        VStack(spacing: 16) {
            Picker("View", selection: $selectedTab) {
                Text("Tasks").tag(0)
                Text("Time Entries").tag(1)
            }
            .pickerStyle(.segmented)

            if selectedTab == 0 {
                tasksSection
            } else {
                timeEntriesSection
            }
        }
    }

    // MARK: - Tasks Section

    private var tasksSection: some View {
        VStack(spacing: 12) {
            if viewModel.tasks.isEmpty {
                emptySection(icon: "checklist", message: "No tasks yet")
            } else {
                ForEach(viewModel.tasks) { task in
                    TaskItemRow(task: task)
                }
            }
        }
    }

    // MARK: - Time Entries Section

    private var timeEntriesSection: some View {
        VStack(spacing: 12) {
            if viewModel.timeEntries.isEmpty {
                emptySection(icon: "clock", message: "No time entries yet")
            } else {
                ForEach(viewModel.timeEntries) { entry in
                    TimeEntryItemRow(entry: entry)
                }
            }
        }
    }

    // MARK: - Helper Views

    private var statusBadge: some View {
        Text(viewModel.project.isActive == true ? "Active" : "Archived")
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(viewModel.project.isActive == true ? Color.alphaSuccess.opacity(0.1) : Color.alphaSecondaryText.opacity(0.1))
            .foregroundColor(viewModel.project.isActive == true ? .alphaSuccess : .alphaSecondaryText)
            .cornerRadius(6)
    }

    private var projectColor: Color {
        guard let hexColor = viewModel.project.color else {
            return .alphaInfo
        }
        return Color(hex: hexColor)
    }

    private func emptySection(icon: String, message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.alphaSecondaryText)

            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.alphaSecondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color.alphaCardBackground)
        .cornerRadius(12)
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// MARK: - Stat Card Component

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.alphaPrimaryText)

            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.alphaSecondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.alphaCardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Task Item Row

struct TaskItemRow: View {
    let task: ProjectTask

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(task.isActive == true ? Color.alphaSuccess : Color.alphaSecondaryText)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.alphaPrimaryText)

                if let desc = task.description, !desc.isEmpty {
                    Text(desc)
                        .font(.system(size: 13))
                        .foregroundColor(.alphaSecondaryText)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let rate = task.rate {
                Text(String(format: "$%.2f", rate))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.alphaInfo)
            }
        }
        .padding()
        .background(Color.alphaCardBackground)
        .cornerRadius(10)
    }
}

// MARK: - Time Entry Item Row

struct TimeEntryItemRow: View {
    let entry: TimeEntry

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(formatDate(entry.startAt))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.alphaPrimaryText)

                if let notes = entry.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.system(size: 13))
                        .foregroundColor(.alphaSecondaryText)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(formatDuration(entry.durationMinutes))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.alphaPrimaryText)

                Text(entry.status.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.timeEntryStatusColor(entry.status).opacity(0.1))
                    .foregroundColor(Color.timeEntryStatusColor(entry.status))
                    .cornerRadius(4)
            }
        }
        .padding()
        .background(Color.alphaCardBackground)
        .cornerRadius(10)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return "\(hours)h \(mins)m"
        }
        return "\(mins)m"
    }
}

// MARK: - Preview

#Preview("Project Detail") {
    NavigationStack {
        ProjectDetailView(project: .preview)
    }
}
