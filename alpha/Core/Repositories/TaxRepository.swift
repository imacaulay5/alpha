//
//  TaxRepository.swift
//  alpha
//
//  Created by Claude Code on 2/1/26.
//

import Foundation
import Supabase

class TaxRepository {
    private let supabase = SupabaseClientManager.shared.client
    private let ownershipResolver = OwnershipResolver()
    private let expenseRepository = ExpenseRepository()
    private let invoiceRepository = InvoiceRepository()

    func fetchTaxDashboard() async throws -> TaxDashboard {
        let scope = try await ownershipResolver.currentScope()
        async let filingsTask = fetchTaxFilings(userId: scope.userId)
        async let expensesTask = expenseRepository.fetchExpenses()
        async let invoicesTask = invoiceRepository.fetchInvoices(limit: 500)

        let filings = (try? await filingsTask) ?? []
        let expenses = (try? await expensesTask) ?? []
        let invoices = (try? await invoicesTask) ?? []
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())

        let taxYearExpenses = expenses.filter {
            calendar.component(.year, from: $0.expenseDate) == currentYear
        }
        let taxYearInvoices = invoices.filter {
            calendar.component(.year, from: $0.issueDate) == currentYear &&
            [.sent, .paid, .overdue].contains($0.status)
        }

        let expenseTotal = taxYearExpenses.reduce(0) { $0 + $1.amount }
        let incomeTotal = taxYearInvoices.reduce(0) { $0 + $1.total }
        let netIncome = max(0, incomeTotal - expenseTotal)
        let selfEmploymentTax = estimateSelfEmploymentTax(netIncome * 0.9235)
        let federalTax = estimateFederalTax(max(0, netIncome - (selfEmploymentTax / 2)))
        let estimatedTax = federalTax + selfEmploymentTax

        let upcomingDeadlines = filings
            .filter { $0.status != .filed && $0.status != .accepted }
            .map { filing in
                TaxDeadline(
                    id: filing.id,
                    type: filing.type,
                    dueDate: filing.dueDate,
                    description: filing.name,
                    amount: filing.amount,
                    status: filing.dueDate < Date() ? .overdue : .pending
                )
            }
            .sorted { $0.dueDate < $1.dueDate }

        let filedCount = filings.filter { $0.status == .filed || $0.status == .accepted }.count
        let compliancePercentage = filings.isEmpty
            ? 100
            : (Double(filedCount) / Double(filings.count)) * 100

        let uncategorizedExpenseCount = taxYearExpenses.filter { $0.category == .other }.count
        let overdueFilingCount = upcomingDeadlines.filter { $0.status == .overdue }.count
        let exportWarningCount = [
            overdueFilingCount,
            uncategorizedExpenseCount,
            taxYearExpenses.isEmpty ? 1 : 0,
            taxYearInvoices.isEmpty ? 1 : 0
        ].filter { $0 > 0 }.count

        let nextDeadline = upcomingDeadlines.first

        return TaxDashboard(
            taxLiability: TaxLiability(
                estimatedQuarterly: estimatedTax / 4,
                yearToDate: estimatedTax,
                nextPayment: nextDeadline?.amount ?? estimatedTax / 4,
                nextPaymentDate: nextDeadline?.dueDate ?? nextEstimatedTaxDueDate()
            ),
            complianceRate: ComplianceRate(
                percentage: compliancePercentage,
                filedOnTime: filedCount,
                totalRequired: filings.count
            ),
            upcomingDeadlines: upcomingDeadlines,
            filings: filings.sorted { $0.dueDate < $1.dueDate },
            taxExpenseCount: taxYearExpenses.count,
            taxExpenseTotal: expenseTotal,
            taxIncomeCount: taxYearInvoices.count,
            taxIncomeTotal: incomeTotal,
            exportWarningCount: exportWarningCount
        )
    }

    private func fetchTaxFilings(userId: String) async throws -> [TaxFiling] {
        let response = try await supabase
            .from("tax_filings")
            .select()
            .eq("user_id", value: userId)
            .order("due_date")
            .execute()

        let rows = try JSONDecoder().decode([TaxFilingRowDTO].self, from: response.data)
        return rows.map { $0.taxFiling }
    }

    private func estimateFederalTax(_ income: Double) -> Double {
        let standardDeduction = 14_600.0
        var taxableIncome = max(0, income - standardDeduction)
        var tax = 0.0

        let brackets: [(limit: Double, rate: Double)] = [
            (11_600, 0.10),
            (47_150, 0.12),
            (100_525, 0.22),
            (191_950, 0.24),
            (243_725, 0.32),
            (.greatestFiniteMagnitude, 0.35)
        ]

        var previousLimit = 0.0
        for bracket in brackets where taxableIncome > 0 {
            let taxable = min(taxableIncome, bracket.limit - previousLimit)
            tax += taxable * bracket.rate
            taxableIncome -= taxable
            previousLimit = bracket.limit
        }

        return tax
    }

    private func estimateSelfEmploymentTax(_ netEarnings: Double) -> Double {
        guard netEarnings > 0 else { return 0 }
        let socialSecurityWageBase = 168_600.0
        let socialSecurity = min(netEarnings, socialSecurityWageBase) * 0.124
        let medicare = netEarnings * 0.029
        return socialSecurity + medicare
    }

    private func nextEstimatedTaxDueDate() -> Date {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())
        let candidates = [
            DateComponents(year: year, month: 4, day: 15),
            DateComponents(year: year, month: 6, day: 16),
            DateComponents(year: year, month: 9, day: 15),
            DateComponents(year: year + 1, month: 1, day: 15)
        ].compactMap { calendar.date(from: $0) }

        return candidates.first { $0 >= Date() } ?? candidates.last ?? Date()
    }
}

private struct TaxFilingRowDTO: Decodable {
    let id: String
    let name: String
    let formType: String
    let taxPeriodStart: String?
    let taxPeriodEnd: String?
    let dueDate: String
    let filedDate: String?
    let status: FilingStatus
    let amountDue: Double?
    let amountPaid: Double?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case formType = "form_type"
        case taxPeriodStart = "tax_period_start"
        case taxPeriodEnd = "tax_period_end"
        case dueDate = "due_date"
        case filedDate = "filed_date"
        case status
        case amountDue = "amount_due"
        case amountPaid = "amount_paid"
        case notes
    }

    var taxFiling: TaxFiling {
        let due = Self.parseDate(dueDate) ?? Date()
        let filed = filedDate.flatMap(Self.parseDate) ?? due
        return TaxFiling(
            id: id,
            type: Self.deadlineType(formType: formType, name: name),
            filingDate: filed,
            taxYear: Calendar.current.component(.year, from: due),
            status: status,
            amount: amountDue ?? amountPaid,
            name: name,
            formType: formType,
            dueDate: due,
            taxPeriodStart: taxPeriodStart.flatMap(Self.parseDate),
            taxPeriodEnd: taxPeriodEnd.flatMap(Self.parseDate),
            notes: notes
        )
    }

    nonisolated private static func parseDate(_ value: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd"

        if let date = dateFormatter.date(from: value) {
            return date
        }

        return ISO8601DateFormatter().date(from: value)
    }

    nonisolated private static func deadlineType(formType: String, name: String) -> TaxDeadlineType {
        let normalized = "\(formType) \(name)".lowercased()

        if normalized.contains("1099") {
            return .estimated1099
        }

        if normalized.contains("sales") {
            return .salesTax
        }

        if normalized.contains("payroll") {
            return .payrollTax
        }

        if normalized.contains("1040-es") || normalized.contains("estimate") || normalized.contains("quarter") {
            return .quarterlyEstimate
        }

        return .annualReturn
    }
}
