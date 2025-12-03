//
//  Project.swift
//  alpha
//
//  Created by Claude Code on 11/25/25.
//

import Foundation

enum BillingModel: String, Codable {
    case hourly = "HOURLY"
    case fixed = "FIXED"
    case retainer = "RETAINER"
    case milestone = "MILESTONE"
    case taskBased = "TASK_BASED"
    case notBillable = "NOT_BILLABLE"

    var displayName: String {
        switch self {
        case .hourly:
            return "Hourly Rate"
        case .fixed:
            return "Fixed Price"
        case .retainer:
            return "Monthly Retainer"
        case .milestone:
            return "Milestone-Based"
        case .taskBased:
            return "Task-Based"
        case .notBillable:
            return "Not Billable"
        }
    }
}

struct Project: Codable, Identifiable {
    let id: String
    let organizationId: String
    let clientId: String?
    let name: String
    let description: String?
    let billingModel: BillingModel
    let rate: Double?
    let budget: Double?
    let startDate: Date?
    let endDate: Date?
    let isActive: Bool
    let color: String?
    let tags: [String]?
    let createdAt: Date
    let updatedAt: Date

    // Populated by backend joins
    let client: Client?

    enum CodingKeys: String, CodingKey {
        case id
        case organizationId = "organization_id"
        case clientId = "client_id"
        case name
        case description
        case billingModel = "billing_model"
        case rate
        case budget
        case startDate = "start_date"
        case endDate = "end_date"
        case isActive = "is_active"
        case color
        case tags
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case client
    }

    // Computed properties
    var displayRate: String {
        guard let rate = rate else { return "N/A" }

        switch billingModel {
        case .hourly:
            return String(format: "$%.2f/hr", rate)
        case .fixed:
            return String(format: "$%.2f", rate)
        case .retainer:
            return String(format: "$%.2f/mo", rate)
        case .taskBased:
            return String(format: "$%.2f/task", rate)
        case .milestone:
            return String(format: "$%.2f", rate)
        case .notBillable:
            return "Not Billable"
        }
    }

    var isOverBudget: Bool {
        guard let budget = budget, budget > 0 else { return false }
        // This would need actual spent amount from backend
        return false
    }
}

// MARK: - Preview Helpers
extension Project {
    static let preview = Project(
        id: "project_1",
        organizationId: "org_1",
        clientId: "client_1",
        name: "Website Redesign",
        description: "Complete overhaul of company website",
        billingModel: .hourly,
        rate: 150.0,
        budget: 50000.0,
        startDate: Date(),
        endDate: Date().addingTimeInterval(60 * 60 * 24 * 90), // 90 days
        isActive: true,
        color: "#007AFF",
        tags: ["web", "design", "frontend"],
        createdAt: Date(),
        updatedAt: Date(),
        client: .preview
    )

    static let previewFixed = Project(
        id: "project_2",
        organizationId: "org_1",
        clientId: "client_1",
        name: "Mobile App Development",
        description: "iOS and Android app",
        billingModel: .fixed,
        rate: 75000.0,
        budget: 75000.0,
        startDate: Date(),
        endDate: Date().addingTimeInterval(60 * 60 * 24 * 180), // 180 days
        isActive: true,
        color: "#34C759",
        tags: ["mobile", "ios", "android"],
        createdAt: Date(),
        updatedAt: Date(),
        client: .preview
    )
}
