//
//  PaymentRepository.swift
//  alpha
//
//  Created by Claude Code on 2/1/26.
//

import Foundation
import Supabase

class PaymentRepository {
    private let supabase = SupabaseClientManager.shared.client

    func createPayment(
        amount: Double,
        paymentMethod: String,
        reference: String,
        paymentDate: Date
    ) async throws -> Payment {
        let insert = PaymentInsert(
            amount: amount,
            paymentMethod: paymentMethod,
            reference: reference,
            paymentDate: paymentDate.iso8601String
        )

        let response = try await supabase
            .from("payments")
            .insert(insert)
            .select()
            .single()
            .execute()

        let payment: Payment = try JSONDecoder().decode(Payment.self, from: response.data)
        return payment
    }

    func fetchPayments() async throws -> [Payment] {
        let response = try await supabase
            .from("payments")
            .select("*")
            .order("payment_date", ascending: false)
            .execute()

        let payments: [Payment] = try JSONDecoder().decode([Payment].self, from: response.data)
        return payments
    }
}

// MARK: - Payment Model (if not already defined elsewhere)

struct Payment: Codable, Identifiable {
    let id: String
    let amount: Double
    let paymentMethod: String
    let reference: String?
    let paymentDate: Date

    enum CodingKeys: String, CodingKey {
        case id
        case amount
        case paymentMethod = "payment_method"
        case reference
        case paymentDate = "payment_date"
    }
}

// MARK: - Insert DTO

struct PaymentInsert: Codable {
    let amount: Double
    let paymentMethod: String
    let reference: String
    let paymentDate: String

    enum CodingKeys: String, CodingKey {
        case amount
        case paymentMethod = "payment_method"
        case reference
        case paymentDate = "payment_date"
    }
}
