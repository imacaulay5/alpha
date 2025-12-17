//
//  QuickEntryViewModel.swift
//  alpha
//
//  Created by Claude Code on 12/16/25.
//

import Foundation
import Combine

@MainActor
class QuickEntryViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var selectedProject: Project?
    @Published var tasks: [ProjectTask] = []
    @Published var selectedTask: ProjectTask?
    @Published var date: Date = Date()
    @Published var durationHours: Int = 1
    @Published var durationMinutes: Int = 0
    @Published var notes: String = ""
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?

    private let apiClient = APIClient.shared

    // MARK: - Computed Properties

    var canSave: Bool {
        selectedProject != nil && totalDurationMinutes > 0
    }

    var totalDurationMinutes: Int {
        (durationHours * 60) + durationMinutes
    }

    // MARK: - Public Methods

    func loadProjects() async {
        isLoading = true
        errorMessage = nil

        do {
            projects = try await apiClient.get("/projects")
            print("✅ Successfully loaded \(projects.count) projects")
        } catch {
            print("❌ Load projects error: \(error)")
            if let apiError = error as? APIError {
                print("API Error details: \(apiError.errorDescription ?? "Unknown")")
            }
            errorMessage = "Failed to load projects: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func loadTasks(for projectId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            tasks = try await apiClient.get("/projects/\(projectId)/tasks")
        } catch {
            errorMessage = "Failed to load tasks: \(error.localizedDescription)"
            tasks = []
        }

        isLoading = false
    }

    func onProjectSelected(_ project: Project?) async {
        selectedProject = project
        selectedTask = nil
        tasks = []

        if let projectId = project?.id {
            await loadTasks(for: projectId)
        }
    }

    func saveEntry() async -> Bool {
        guard canSave else { return false }

        isSaving = true
        errorMessage = nil

        struct CreateTimeEntryRequest: Encodable {
            let projectId: String
            let taskId: String?
            let startAt: Date
            let endAt: Date
            let durationMinutes: Int
            let notes: String?
            let source: String

            enum CodingKeys: String, CodingKey {
                case projectId = "project_id"
                case taskId = "task_id"
                case startAt = "start_at"
                case endAt = "end_at"
                case durationMinutes = "duration_minutes"
                case notes
                case source
            }
        }

        do {
            guard let projectId = selectedProject?.id else {
                errorMessage = "Please select a project"
                isSaving = false
                return false
            }

            // Calculate start and end times based on date and duration
            let calendar = Calendar.current
            let endTime = calendar.date(bySettingHour: calendar.component(.hour, from: Date()),
                                       minute: calendar.component(.minute, from: Date()),
                                       second: 0,
                                       of: date) ?? date
            let startTime = endTime.addingTimeInterval(-Double(totalDurationMinutes * 60))

            let request = CreateTimeEntryRequest(
                projectId: projectId,
                taskId: selectedTask?.id,
                startAt: startTime,
                endAt: endTime,
                durationMinutes: totalDurationMinutes,
                notes: notes.isEmpty ? nil : notes,
                source: "MOBILE"
            )

            let _: TimeEntry = try await apiClient.post("/time-entries", body: request)

            // Reset form on success
            resetForm()
            isSaving = false
            return true

        } catch {
            errorMessage = "Failed to save time entry: \(error.localizedDescription)"
            isSaving = false
            return false
        }
    }

    func resetForm() {
        selectedProject = nil
        selectedTask = nil
        tasks = []
        date = Date()
        durationHours = 1
        durationMinutes = 0
        notes = ""
        errorMessage = nil
    }
}
