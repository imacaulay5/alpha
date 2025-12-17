//
//  Task.swift
//  alpha
//
//  Created by Claude Code on 11/25/25.
//  Note: Renamed to ProjectTask to avoid conflict with Swift's Task type
//

import Foundation

struct ProjectTask: Codable, Identifiable, Hashable {
    let id: String
    let projectId: String?
    let name: String
    let description: String?
    let rate: Double?
    let estimatedHours: Double?
    let isActive: Bool?
    let createdAt: Date?
    let updatedAt: Date?

    // Populated by backend joins
    let project: Project?

    enum CodingKeys: String, CodingKey {
        case id
        case projectId = "project_id"
        case name
        case description
        case rate
        case estimatedHours = "estimated_hours"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case project
    }

    // Computed properties
    var displayRate: String {
        guard let rate = rate else {
            return project?.displayRate ?? "N/A"
        }
        return String(format: "$%.2f/hr", rate)
    }

    var effectiveRate: Double? {
        return rate ?? project?.rate
    }
}

// MARK: - Preview Helpers
extension ProjectTask {
    static let preview = ProjectTask(
        id: "task_1",
        projectId: "project_1",
        name: "UI Design",
        description: "Design mockups and prototypes",
        rate: 175.0,
        estimatedHours: 40.0,
        isActive: true,
        createdAt: Date(),
        updatedAt: Date(),
        project: .preview
    )

    static let previewDevelopment = ProjectTask(
        id: "task_2",
        projectId: "project_1",
        name: "Frontend Development",
        description: "Implement React components",
        rate: nil, // Uses project rate
        estimatedHours: 120.0,
        isActive: true,
        createdAt: Date(),
        updatedAt: Date(),
        project: .preview
    )
}
