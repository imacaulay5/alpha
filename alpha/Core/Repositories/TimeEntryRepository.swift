//
//  TimeEntryRepository.swift
//  alpha
//
//  Created by Claude Code on 12/18/24.
//

import Foundation
import Supabase

class TimeEntryRepository {
    private let supabase = SupabaseClientManager.shared.client

    func fetchTimeEntries(
        startDate: Date? = nil,
        endDate: Date? = nil,
        projectId: String? = nil
    ) async throws -> [TimeEntry] {
        var query = supabase
            .from("time_entries")
            .select("""
                *,
                project:projects(id, name, billing_model, rate),
                task:tasks(id, name, rate)
            """)

        // Apply filters first
        if let startDate = startDate {
            query = query.gte("start_at", value: startDate.iso8601String)
        }

        if let endDate = endDate {
            query = query.lte("start_at", value: endDate.iso8601String)
        }

        if let projectId = projectId {
            query = query.eq("project_id", value: projectId)
        }

        // Then apply order and execute
        let response = try await query
            .order("start_at", ascending: false)
            .execute()

        let entries: [TimeEntry] = try JSONDecoder().decode([TimeEntry].self, from: response.data)
        return entries
    }

    func createTimeEntry(
        projectId: String,
        taskId: String?,
        startAt: Date,
        endAt: Date,
        durationMinutes: Int,
        notes: String?,
        source: String
    ) async throws -> TimeEntry {
        let insert = TimeEntryInsert(
            projectId: projectId,
            taskId: taskId,
            startAt: startAt.iso8601String,
            endAt: endAt.iso8601String,
            durationMinutes: durationMinutes,
            notes: notes,
            source: source,
            status: "SUBMITTED"
        )

        let response = try await supabase
            .from("time_entries")
            .insert(insert)
            .select()
            .single()
            .execute()

        let entry: TimeEntry = try JSONDecoder().decode(TimeEntry.self, from: response.data)
        return entry
    }

    func deleteTimeEntry(id: String) async throws {
        try await supabase
            .from("time_entries")
            .delete()
            .eq("id", value: id)
            .execute()
    }
}

// MARK: - Insert DTOs

struct TimeEntryInsert: Codable {
    let projectId: String
    let taskId: String?
    let startAt: String
    let endAt: String
    let durationMinutes: Int
    let notes: String?
    let source: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case projectId = "project_id"
        case taskId = "task_id"
        case startAt = "start_at"
        case endAt = "end_at"
        case durationMinutes = "duration_minutes"
        case notes
        case source
        case status
    }
}

// MARK: - Date Extension

extension Date {
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }
}
