//
//  DashboardRepository.swift
//  alpha
//
//  Created by Claude Code on 2/1/26.
//

import Foundation
import Supabase

class DashboardRepository {
    private let supabase = SupabaseClientManager.shared.client
    private let invoiceRepository = InvoiceRepository()
    private let timeEntryRepository = TimeEntryRepository()
    private let expenseRepository = ExpenseRepository()

    func fetchBusinessMetrics() async throws -> BusinessMetrics {
        // Calculate metrics from actual data
        let now = Date()
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!

        // Fetch time entries for this month
        let timeEntries = try await timeEntryRepository.fetchTimeEntries(
            startDate: startOfMonth,
            endDate: now
        )

        // Calculate billable hours
        let billableHours = timeEntries.reduce(0.0) { total, entry in
            total + entry.durationHours
        }

        // Fetch invoices
        let invoices = try await invoiceRepository.fetchInvoices()
        let paidInvoices = invoices.filter { $0.status == .paid }
        let totalRevenue = paidInvoices.reduce(0.0) { $0 + $1.total }
        let outstandingInvoices = invoices.filter { $0.status == .sent || $0.status == .draft }
        let outstandingRevenue = outstandingInvoices.reduce(0.0) { $0 + $1.total }
        let pendingInvoicesCount = outstandingInvoices.count

        // Return metrics with correct parameter order matching BusinessMetrics struct
        return BusinessMetrics(
            totalRevenue: totalRevenue,
            revenueChangePercentage: 0,
            revenueTrend: .neutral,
            outstandingRevenue: outstandingRevenue,
            outstandingChangePercentage: 0,
            outstandingTrend: .neutral,
            billableHoursThisMonth: billableHours,
            hoursChangePercentage: 0,
            hoursTrend: .neutral,
            pendingInvoices: pendingInvoicesCount,
            invoicesChangePercentage: 0,
            invoicesTrend: .neutral,
            totalBills: nil,
            billsChangePercentage: nil,
            billsTrend: nil,
            totalPayments: nil,
            paymentsChangePercentage: nil,
            paymentsTrend: nil,
            teamHours: nil,
            teamHoursChangePercentage: nil,
            teamHoursTrend: nil,
            pendingApprovals: nil,
            approvalsChangePercentage: nil,
            approvalsTrend: nil
        )
    }

    func fetchRecentActivity() async throws -> RecentActivity {
        // For now, return empty activity
        // This could be populated from a dedicated activity/audit log table
        return RecentActivity(activities: [])
    }
}
