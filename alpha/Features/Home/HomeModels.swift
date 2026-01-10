//
//  HomeModels.swift
//  alpha
//
//  Created by Claude Code on 12/23/24.
//

import Foundation

// MARK: - Data Models

struct BusinessMetrics: Codable, Sendable {
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

    enum CodingKeys: String, CodingKey {
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
    }
}

struct RecentActivity: Codable, Sendable {
    let activities: [ActivityItem]
}
