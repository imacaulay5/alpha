//
//  ExpenseRepository.swift
//  alpha
//
//  Created by Claude Code on 2/1/26.
//

import Foundation
import Supabase

class ExpenseRepository {
    private let supabase = SupabaseClientManager.shared.client

    func fetchExpenses() async throws -> [Expense] {
        let response = try await supabase
            .from("expenses")
            .select("""
                *,
                project:projects(id, name)
            """)
            .order("expense_date", ascending: false)
            .execute()

        let expenses: [Expense] = try JSONDecoder().decode([Expense].self, from: response.data)
        return expenses
    }

    func fetchExpense(id: String) async throws -> Expense {
        let response = try await supabase
            .from("expenses")
            .select("""
                *,
                project:projects(id, name)
            """)
            .eq("id", value: id)
            .single()
            .execute()

        let expense: Expense = try JSONDecoder().decode(Expense.self, from: response.data)
        return expense
    }

    func createExpense(
        description: String,
        amount: Double,
        currency: String,
        category: String,
        merchant: String?,
        expenseDate: Date,
        projectId: String?,
        notes: String?,
        status: String
    ) async throws -> Expense {
        let insert = ExpenseInsert(
            description: description,
            amount: amount,
            currency: currency,
            category: category,
            merchant: merchant,
            expenseDate: expenseDate.iso8601String,
            projectId: projectId,
            notes: notes,
            status: status
        )

        let response = try await supabase
            .from("expenses")
            .insert(insert)
            .select()
            .single()
            .execute()

        let expense: Expense = try JSONDecoder().decode(Expense.self, from: response.data)
        return expense
    }

    func updateExpense(
        id: String,
        description: String,
        amount: Double,
        currency: String,
        category: String,
        merchant: String?,
        expenseDate: Date,
        projectId: String?,
        notes: String?,
        status: String
    ) async throws -> Expense {
        let update = ExpenseInsert(
            description: description,
            amount: amount,
            currency: currency,
            category: category,
            merchant: merchant,
            expenseDate: expenseDate.iso8601String,
            projectId: projectId,
            notes: notes,
            status: status
        )

        let response = try await supabase
            .from("expenses")
            .update(update)
            .eq("id", value: id)
            .select()
            .single()
            .execute()

        let expense: Expense = try JSONDecoder().decode(Expense.self, from: response.data)
        return expense
    }

    func updateStatus(id: String, status: String) async throws -> Expense {
        let update = ExpenseStatusUpdate(status: status)

        let response = try await supabase
            .from("expenses")
            .update(update)
            .eq("id", value: id)
            .select("""
                *,
                project:projects(id, name)
            """)
            .single()
            .execute()

        let expense: Expense = try JSONDecoder().decode(Expense.self, from: response.data)
        return expense
    }

    func deleteExpense(id: String) async throws {
        try await supabase
            .from("expenses")
            .delete()
            .eq("id", value: id)
            .execute()
    }
}

// MARK: - Insert DTOs

struct ExpenseInsert: Codable {
    let description: String
    let amount: Double
    let currency: String
    let category: String
    let merchant: String?
    let expenseDate: String
    let projectId: String?
    let notes: String?
    let status: String

    enum CodingKeys: String, CodingKey {
        case description
        case amount
        case currency
        case category
        case merchant
        case expenseDate = "expense_date"
        case projectId = "project_id"
        case notes
        case status
    }
}

struct ExpenseStatusUpdate: Codable {
    let status: String
}
