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

    func fetchTaxDashboard() async throws -> TaxDashboard {
        // For now, create a mock dashboard since the tax data likely needs
        // to be computed from multiple tables. This can be replaced with
        // actual RPC functions when available.
        return TaxDashboard(
            taxLiability: TaxLiability(
                estimatedQuarterly: 0,
                yearToDate: 0,
                nextPayment: 0,
                nextPaymentDate: Date()
            ),
            complianceRate: ComplianceRate(
                percentage: 100,
                filedOnTime: 0,
                totalRequired: 0
            ),
            upcomingDeadlines: [],
            filings: []
        )
    }
}
