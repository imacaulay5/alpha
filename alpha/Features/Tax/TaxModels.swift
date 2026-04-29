//
//  TaxModels.swift
//  alpha
//
//  Created by Claude Code on 01/12/26.
//

import Foundation
import SwiftUI

// MARK: - Tax Dashboard Data

struct TaxDashboard: Codable, Sendable {
    let taxLiability: TaxLiability
    let complianceRate: ComplianceRate
    let upcomingDeadlines: [TaxDeadline]
    let filings: [TaxFiling]
    let taxExpenseCount: Int
    let taxExpenseTotal: Double
    let taxIncomeCount: Int
    let taxIncomeTotal: Double
    let exportWarningCount: Int

    enum CodingKeys: String, CodingKey {
        case taxLiability = "tax_liability"
        case complianceRate = "compliance_rate"
        case upcomingDeadlines = "upcoming_deadlines"
        case filings
        case taxExpenseCount = "tax_expense_count"
        case taxExpenseTotal = "tax_expense_total"
        case taxIncomeCount = "tax_income_count"
        case taxIncomeTotal = "tax_income_total"
        case exportWarningCount = "export_warning_count"
    }
}

// MARK: - Tax Liability

struct TaxLiability: Codable, Sendable {
    let estimatedQuarterly: Double
    let yearToDate: Double
    let nextPayment: Double
    let nextPaymentDate: Date

    enum CodingKeys: String, CodingKey {
        case estimatedQuarterly = "estimated_quarterly"
        case yearToDate = "year_to_date"
        case nextPayment = "next_payment"
        case nextPaymentDate = "next_payment_date"
    }
}

// MARK: - Compliance Rate

struct ComplianceRate: Codable, Sendable {
    let percentage: Double
    let filedOnTime: Int
    let totalRequired: Int

    enum CodingKeys: String, CodingKey {
        case percentage
        case filedOnTime = "filed_on_time"
        case totalRequired = "total_required"
    }
}

// MARK: - Tax Deadline

struct TaxDeadline: Codable, Sendable, Identifiable {
    let id: String
    let type: TaxDeadlineType
    let dueDate: Date
    let description: String
    let amount: Double?
    let status: DeadlineStatus

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case dueDate = "due_date"
        case description
        case amount
        case status
    }

    // Computed properties
    var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
    }

    var urgency: DeadlineUrgency {
        let days = daysRemaining
        if days <= 3 { return .critical }
        if days <= 7 { return .warning }
        return .normal
    }
}

enum TaxDeadlineType: String, Codable {
    case quarterlyEstimate = "QUARTERLY_ESTIMATE"
    case annualReturn = "ANNUAL_RETURN"
    case salesTax = "SALES_TAX"
    case payrollTax = "PAYROLL_TAX"
    case estimated1099 = "1099_FILING"

    var icon: String {
        switch self {
        case .quarterlyEstimate: return "calendar.badge.clock"
        case .annualReturn: return "doc.text.fill"
        case .salesTax: return "cart.fill"
        case .payrollTax: return "person.2.fill"
        case .estimated1099: return "doc.plaintext"
        }
    }

    var displayName: String {
        switch self {
        case .quarterlyEstimate: return "Quarterly Estimate"
        case .annualReturn: return "Annual Return"
        case .salesTax: return "Sales Tax"
        case .payrollTax: return "Payroll Tax"
        case .estimated1099: return "1099 Filing"
        }
    }
}

enum DeadlineStatus: String, Codable {
    case pending = "PENDING"
    case filed = "FILED"
    case overdue = "OVERDUE"
    case scheduled = "SCHEDULED"
}

enum DeadlineUrgency {
    case critical  // ≤3 days
    case warning   // ≤7 days
    case normal    // >7 days

    var color: Color {
        switch self {
        case .critical: return .red
        case .warning: return .orange
        case .normal: return .blue
        }
    }

    var backgroundColor: Color {
        switch self {
        case .critical: return .red.opacity(0.1)
        case .warning: return .orange.opacity(0.1)
        case .normal: return .blue.opacity(0.1)
        }
    }
}

// MARK: - Tax Filing

struct TaxFiling: Codable, Sendable, Identifiable {
    let id: String
    let type: TaxDeadlineType
    let filingDate: Date
    let taxYear: Int
    let status: FilingStatus
    let amount: Double?
    let name: String
    let formType: String
    let dueDate: Date
    let taxPeriodStart: Date?
    let taxPeriodEnd: Date?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case filingDate = "filing_date"
        case taxYear = "tax_year"
        case status
        case amount
        case name
        case formType = "form_type"
        case dueDate = "due_date"
        case taxPeriodStart = "tax_period_start"
        case taxPeriodEnd = "tax_period_end"
        case notes
    }
}

enum FilingStatus: String, Codable {
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case filed = "filed"
    case accepted = "accepted"
    case rejected = "rejected"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        let normalized = rawValue.lowercased()
        self = FilingStatus(rawValue: normalized) ?? .notStarted
    }

    var displayName: String {
        switch self {
        case .notStarted: return "Not Started"
        case .inProgress: return "In Progress"
        case .filed: return "Filed"
        case .accepted: return "Accepted"
        case .rejected: return "Rejected"
        }
    }

    var color: Color {
        switch self {
        case .notStarted: return .gray
        case .inProgress: return .orange
        case .filed: return .blue
        case .accepted: return .green
        case .rejected: return .red
        }
    }
}
