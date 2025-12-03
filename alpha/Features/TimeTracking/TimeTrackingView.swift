//
//  TimeTrackingView.swift
//  alpha
//
//  Created by Claude Code on 11/25/25.
//

import SwiftUI
import Combine

@MainActor
class TimeTrackingViewModel: ObservableObject {
    @Published var isRunning = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var todaysEntries: [TimeEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var selectedProjectId: String?
    @Published var selectedTaskId: String?
    @Published var notes: String = ""

    private var timer: Timer?
    private var startTime: Date?
    private let apiClient = APIClient.shared

    func startTimer() {
        isRunning = true
        startTime = Date()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.startTime else { return }
            Task { @MainActor in
                self.elapsedTime = Date().timeIntervalSince(startTime)
            }
        }
    }

    func stopTimer() async {
        guard let startTime = startTime else { return }

        isRunning = false
        timer?.invalidate()
        timer = nil

        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        let durationMinutes = Int(duration / 60)

        // Save time entry to API if we have a project selected
        if let projectId = selectedProjectId, durationMinutes > 0 {
            await saveTimeEntry(
                projectId: projectId,
                taskId: selectedTaskId,
                startAt: startTime,
                endAt: endTime,
                durationMinutes: durationMinutes,
                notes: notes
            )
        }

        // Reset timer state
        elapsedTime = 0
        self.startTime = nil
        notes = ""
    }

    func saveTimeEntry(projectId: String, taskId: String?, startAt: Date, endAt: Date, durationMinutes: Int, notes: String) async {
        struct CreateTimeEntryRequest: Codable {
            let projectId: String
            let taskId: String?
            let startAt: Date
            let endAt: Date
            let durationMinutes: Int
            let notes: String?
            let source: String
        }

        do {
            let request = CreateTimeEntryRequest(
                projectId: projectId,
                taskId: taskId,
                startAt: startAt,
                endAt: endAt,
                durationMinutes: durationMinutes,
                notes: notes.isEmpty ? nil : notes,
                source: "MOBILE"
            )

            let _: TimeEntry = try await apiClient.post("/time-entries", body: request)

            // Reload today's entries to show the new entry
            await loadTodaysEntries()
        } catch {
            errorMessage = "Failed to save time entry: \(error.localizedDescription)"
        }
    }

    func loadTodaysEntries() async {
        isLoading = true
        errorMessage = nil

        do {
            todaysEntries = try await apiClient.get("/time-entries/today")
        } catch {
            errorMessage = "Failed to load entries: \(error.localizedDescription)"
            todaysEntries = []
        }

        isLoading = false
    }

    func deleteEntry(_ entryId: String) async {
        do {
            let _: [String: Bool] = try await apiClient.delete("/time-entries/\(entryId)")
            await loadTodaysEntries()
        } catch {
            errorMessage = "Failed to delete entry: \(error.localizedDescription)"
        }
    }
}

struct TimeTrackingView: View {
    @StateObject private var viewModel = TimeTrackingViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Timer Display
                    VStack(spacing: 16) {
                        Text(timeString(from: viewModel.elapsedTime))
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(.alphaPrimary)

                        // Timer Controls
                        HStack(spacing: 16) {
                            if viewModel.isRunning {
                                AlphaButton(
                                    "Stop Timer",
                                    style: .outline,
                                    size: .large
                                ) {
                                    Task {
                                        await viewModel.stopTimer()
                                    }
                                }
                            } else {
                                AlphaButton(
                                    "Start Timer",
                                    style: .primary,
                                    size: .large
                                ) {
                                    viewModel.startTimer()
                                }
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.alphaCardBackground)
                    .cornerRadius(16)
                    .padding(.horizontal)

                    // Today's Entries
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Today's Entries")
                                .font(.alphaTitle)
                                .foregroundColor(.alphaPrimaryText)

                            Spacer()

                            Text("0h 0m")
                                .font(.alphaBody)
                                .foregroundColor(.alphaSecondaryText)
                        }
                        .padding(.horizontal)

                        if viewModel.todaysEntries.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "timer")
                                    .font(.system(size: 48))
                                    .foregroundColor(.alphaSecondaryText)

                                Text("No time entries yet")
                                    .font(.alphaBody)
                                    .foregroundColor(.alphaSecondaryText)

                                Text("Start the timer to track your time")
                                    .font(.alphaBodySmall)
                                    .foregroundColor(.alphaTertiaryText)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 48)
                        } else {
                            // TODO: Display entries
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color.alphaGroupedBackground)
            .navigationTitle("Time Tracking")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await viewModel.loadTodaysEntries()
            }
            .task {
                await viewModel.loadTodaysEntries()
            }
        }
    }

    private func timeString(from timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

// MARK: - Preview

#Preview("Time Tracking") {
    TimeTrackingView()
}
