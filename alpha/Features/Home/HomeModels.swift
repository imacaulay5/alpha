//
//  HomeModels.swift
//  alpha
//
//  Created by Claude Code on 12/23/24.
//

import Foundation

// NOTE: TrendDirection enum is defined in Shared/Components/StatisticCard.swift
// and is available throughout the module

// MARK: - Data Models

struct BusinessMetrics: Codable, Sendable {
    // Freelancer Metrics
    let totalRevenue: Double
    let revenueChangePercentage: Double
    let revenueTrend: TrendDirection

    let outstandingRevenue: Double
    let outstandingChangePercentage: Double
    let outstandingTrend: TrendDirection

    let billableHoursThisMonth: Double
    let hoursChangePercentage: Double
    let hoursTrend: TrendDirection

    let pendingInvoices: Int
    let invoicesChangePercentage: Double
    let invoicesTrend: TrendDirection

    // Personal Account Metrics
    let totalBills: Double?
    let billsChangePercentage: Double?
    let billsTrend: TrendDirection?

    let totalPayments: Double?
    let paymentsChangePercentage: Double?
    let paymentsTrend: TrendDirection?

    // Business Account Metrics
    let teamHours: Double?
    let teamHoursChangePercentage: Double?
    let teamHoursTrend: TrendDirection?

    let pendingApprovals: Int?
    let approvalsChangePercentage: Double?
    let approvalsTrend: TrendDirection?

    enum CodingKeys: String, CodingKey {
        // Freelancer
        case totalRevenue = "total_revenue"
        case revenueChangePercentage = "revenue_change_percentage"
        case revenueTrend = "revenue_trend"
        case outstandingRevenue = "outstanding_revenue"
        case outstandingChangePercentage = "outstanding_change_percentage"
        case outstandingTrend = "outstanding_trend"
        case billableHoursThisMonth = "billable_hours_this_month"
        case hoursChangePercentage = "hours_change_percentage"
        case hoursTrend = "hours_trend"
        case pendingInvoices = "pending_invoices"
        case invoicesChangePercentage = "invoices_change_percentage"
        case invoicesTrend = "invoices_trend"

        // Personal
        case totalBills = "total_bills"
        case billsChangePercentage = "bills_change_percentage"
        case billsTrend = "bills_trend"
        case totalPayments = "total_payments"
        case paymentsChangePercentage = "payments_change_percentage"
        case paymentsTrend = "payments_trend"

        // Business
        case teamHours = "team_hours"
        case teamHoursChangePercentage = "team_hours_change_percentage"
        case teamHoursTrend = "team_hours_trend"
        case pendingApprovals = "pending_approvals"
        case approvalsChangePercentage = "approvals_change_percentage"
        case approvalsTrend = "approvals_trend"
    }
}

struct RecentActivity: Codable, Sendable {
    let activities: [ActivityItem]
}
