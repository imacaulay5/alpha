//
//  ProjectRepository.swift
//  alpha
//
//  Created by Claude Code on 12/18/24.
//

import Foundation
import Supabase

class ProjectRepository {
    private let supabase = SupabaseClientManager.shared.client

    func fetchProjects() async throws -> [Project] {
        let response = try await supabase
            .from("projects")
            .select("""
                *,
                client:clients(id, name)
            """)
            .eq("is_active", value: true)
            .order("name")
            .execute()

        let projects: [Project] = try JSONDecoder().decode([Project].self, from: response.data)
        return projects
    }

    func fetchProject(id: String) async throws -> Project {
        let response = try await supabase
            .from("projects")
            .select("""
                *,
                client:clients(id, name),
                tasks:tasks(*)
            """)
            .eq("id", value: id)
            .single()
            .execute()

        let project: Project = try JSONDecoder().decode(Project.self, from: response.data)
        return project
    }

    func updateProjectBilling(
        id: String,
        billingModel: String?,
        rate: Double?,
        budget: Double?
    ) async throws -> Project {
        let updates = ProjectBillingUpdate(
            billingModel: billingModel,
            rate: rate,
            budget: budget
        )

        let response = try await supabase
            .from("projects")
            .update(updates)
            .eq("id", value: id)
            .select()
            .single()
            .execute()

        let project: Project = try JSONDecoder().decode(Project.self, from: response.data)
        return project
    }
}

// MARK: - Update DTOs

struct ProjectBillingUpdate: Codable {
    let billingModel: String?
    let rate: Double?
    let budget: Double?

    enum CodingKeys: String, CodingKey {
        case billingModel = "billing_model"
        case rate
        case budget
    }
}
