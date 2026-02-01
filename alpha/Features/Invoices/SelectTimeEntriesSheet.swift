//
//  SelectTimeEntriesSheet.swift
//  alpha
//
//  Created by Claude Code on 2/1/26.
//

import SwiftUI
import Combine

// MARK: - ViewModel

@MainActor
class SelectTimeEntriesViewModel: ObservableObject {
    @Published var timeEntries: [TimeEntry] = []
    @Published var selectedEntryIds: Set<String> = []
    @Published var projects: [Project] = []
    @Published var selectedProject: Project?
    @Published var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @Published var endDate: Date = Date()
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let timeEntryRepository = TimeEntryRepository()
    private let projectRepository = ProjectRepository()

    // MARK: - Computed Properties

    var filteredEntries: [TimeEntry] {
        var entries = timeEntries

        if let project = selectedProject {
            entries = entries.filter { $0.projectId == project.id }
        }

        return entries
    }

    var selectedEntries: [TimeEntry] {
        filteredEntries.filter { selectedEntryIds.contains($0.id) }
    }

    var totalHours: Double {
        selectedEntries.reduce(0) { $0 + $1.durationHours }
    }

    var totalAmount: Double {
        selectedEntries.reduce(0) { total, entry in
            if let amount = entry.billableAmount {
                return total + amount
            } else if let rate = entry.project?.rate {
                return total + (rate * entry.durationHours)
            }
            return total
        }
    }

    var allSelected: Bool {
        !filteredEntries.isEmpty && filteredEntries.allSatisfy { selectedEntryIds.contains($0.id) }
    }

    // MARK: - Public Methods

    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            async let projectsTask = projectRepository.fetchProjects()
            async let entriesTask = timeEntryRepository.fetchUnbilledTimeEntries(
                startDate: startDate,
                endDate: endDate
            )

            let (loadedProjects, loadedEntries) = try await (projectsTask, entriesTask)
            projects = loadedProjects
            timeEntries = loadedEntries
        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func refreshEntries() async {
        isLoading = true
        errorMessage = nil

        do {
            timeEntries = try await timeEntryRepository.fetchUnbilledTimeEntries(
                projectId: selectedProject?.id,
                startDate: startDate,
                endDate: endDate
            )
        } catch {
            errorMessage = "Failed to load time entries: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func toggleSelection(_ entry: TimeEntry) {
        if selectedEntryIds.contains(entry.id) {
            selectedEntryIds.remove(entry.id)
        } else {
            selectedEntryIds.insert(entry.id)
        }
    }

    func toggleSelectAll() {
        if allSelected {
            // Deselect all filtered entries
            for entry in filteredEntries {
                selectedEntryIds.remove(entry.id)
            }
        } else {
            // Select all filtered entries
            for entry in filteredEntries {
                selectedEntryIds.insert(entry.id)
            }
        }
    }

    func isSelected(_ entry: TimeEntry) -> Bool {
        selectedEntryIds.contains(entry.id)
    }
}

// MARK: - SelectTimeEntriesSheet

struct SelectTimeEntriesSheet: View {
    @Binding var isPresented: Bool
    var onEntriesSelected: ([TimeEntry]) -> Void

    @StateObject private var viewModel = SelectTimeEntriesViewModel()
    @State private var showingFilters = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Bar
                filterBar

                // Content
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading time entries...")
                    Spacer()
                } else if viewModel.filteredEntries.isEmpty {
                    emptyState
                } else {
                    entriesList
                }

                // Summary Footer
                if !viewModel.selectedEntries.isEmpty {
                    summaryFooter
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Select Time Entries")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onEntriesSelected(viewModel.selectedEntries)
                        isPresented = false
                    }
                    .disabled(viewModel.selectedEntries.isEmpty)
                }
            }
            .task {
                await viewModel.loadData()
            }
            .sheet(isPresented: $showingFilters) {
                TimeEntryFiltersSheet(
                    projects: viewModel.projects,
                    selectedProject: $viewModel.selectedProject,
                    startDate: $viewModel.startDate,
                    endDate: $viewModel.endDate,
                    onApply: {
                        showingFilters = false
                        Task {
                            await viewModel.refreshEntries()
                        }
                    }
                )
            }
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: { showingFilters = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text("Filters")
                        if viewModel.selectedProject != nil {
                            Text("(1)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.blue)
                        }
                    }
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(8)
                }

                Spacer()

                Button(action: { viewModel.toggleSelectAll() }) {
                    Text(viewModel.allSelected ? "Deselect All" : "Select All")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                }
            }

            // Active filters display
            if viewModel.selectedProject != nil {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if let project = viewModel.selectedProject {
                            FilterChip(
                                label: project.name,
                                color: Color(hex: project.color ?? "#007AFF")
                            ) {
                                viewModel.selectedProject = nil
                                Task { await viewModel.refreshEntries() }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
    }

    // MARK: - Entries List

    private var entriesList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(viewModel.filteredEntries) { entry in
                    TimeEntrySelectionRow(
                        entry: entry,
                        isSelected: viewModel.isSelected(entry),
                        onToggle: { viewModel.toggleSelection(entry) }
                    )
                }
            }
            .padding()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "clock.badge.checkmark")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Unbilled Time Entries")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            Text("All approved time entries have been invoiced, or none match your filters.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
        }
    }

    // MARK: - Summary Footer

    private var summaryFooter: some View {
        VStack(spacing: 12) {
            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(viewModel.selectedEntries.count) entries selected")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)

                    Text(String(format: "%.1f hours", viewModel.totalHours))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total Amount")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)

                    Text(String(format: "$%.2f", viewModel.totalAmount))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.alphaSuccess)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
    }
}

// MARK: - Time Entry Selection Row

struct TimeEntrySelectionRow: View {
    let entry: TimeEntry
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .blue : .secondary)

                // Entry details
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        if let project = entry.project {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color(hex: project.color ?? "#007AFF"))
                                    .frame(width: 8, height: 8)
                                Text(project.name)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                        }

                        Spacer()

                        Text(entry.startAt, style: .date)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }

                    if let notes = entry.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    HStack {
                        Text(entry.durationFormatted)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)

                        if let task = entry.task {
                            Text("- \(task.name)")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if let amount = entry.billableAmount {
                            Text(String(format: "$%.2f", amount))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.alphaSuccess)
                        } else if let rate = entry.project?.rate {
                            Text(String(format: "$%.2f", rate * entry.durationHours))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.alphaSuccess)
                        }
                    }
                }
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    let color: Color
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.primary)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(uiColor: .tertiarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

// MARK: - Time Entry Filters Sheet

struct TimeEntryFiltersSheet: View {
    let projects: [Project]
    @Binding var selectedProject: Project?
    @Binding var startDate: Date
    @Binding var endDate: Date
    let onApply: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Project", selection: $selectedProject) {
                        Text("All Projects").tag(nil as Project?)
                        ForEach(projects) { project in
                            HStack {
                                Circle()
                                    .fill(Color(hex: project.color ?? "#007AFF"))
                                    .frame(width: 10, height: 10)
                                Text(project.name)
                            }
                            .tag(project as Project?)
                        }
                    }
                } header: {
                    Text("Project")
                }

                Section {
                    DatePicker("From", selection: $startDate, displayedComponents: .date)
                    DatePicker("To", selection: $endDate, displayedComponents: .date)
                } header: {
                    Text("Date Range")
                }

                Section {
                    Button("Reset Filters") {
                        selectedProject = nil
                        startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
                        endDate = Date()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Select Time Entries Sheet") {
    SelectTimeEntriesSheet(
        isPresented: .constant(true),
        onEntriesSelected: { entries in
            print("Selected \(entries.count) entries")
        }
    )
}
