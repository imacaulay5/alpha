//
//  BillLineItem.swift
//  alpha
//
//  Created by Claude Code on 12/18/25.
//

import Foundation
import Supabase

struct BillLineItem: Identifiable, Codable {
    let id: UUID
    var description: String
    var amount: Double
    var category: String

    init(id: UUID = UUID(), description: String = "", amount: Double = 0.0, category: String = "OFFICE_SUPPLIES") {
        self.id = id
        self.description = description
        self.amount = amount
        self.category = category
    }
}

enum BillStatus: String, Codable, CaseIterable {
    case upcoming
    case due
    case paid
    case overdue
    case cancelled

    var displayName: String {
        switch self {
        case .upcoming: return "Upcoming"
        case .due: return "Due"
        case .paid: return "Paid"
        case .overdue: return "Overdue"
        case .cancelled: return "Cancelled"
        }
    }
}

enum BillRecurrence: String, Codable, CaseIterable {
    case none
    case weekly
    case monthly
    case quarterly
    case yearly

    var displayName: String {
        switch self {
        case .none: return "None"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .quarterly: return "Quarterly"
        case .yearly: return "Yearly"
        }
    }
}

struct Bill: Identifiable, Codable {
    let id: String
    let userId: String
    let name: String
    let payee: String
    let amount: Double
    let currency: String
    let category: String
    let dueDate: Date
    let status: BillStatus
    let recurrence: BillRecurrence
    let notes: String?
    let paidAt: Date?
    let autoPay: Bool
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case payee
        case amount
        case currency
        case category
        case dueDate = "due_date"
        case status
        case recurrence
        case notes
        case paidAt = "paid_at"
        case autoPay = "auto_pay"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        name = try container.decode(String.self, forKey: .name)
        payee = try container.decode(String.self, forKey: .payee)
        amount = try container.decode(Double.self, forKey: .amount)
        currency = try container.decodeIfPresent(String.self, forKey: .currency) ?? "USD"
        category = try container.decode(String.self, forKey: .category)
        dueDate = try Self.decodeDate(container, key: .dueDate) ?? Date()
        status = try container.decodeIfPresent(BillStatus.self, forKey: .status) ?? .upcoming
        recurrence = try container.decodeIfPresent(BillRecurrence.self, forKey: .recurrence) ?? .monthly
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        paidAt = try Self.decodeDate(container, key: .paidAt)
        autoPay = try container.decodeIfPresent(Bool.self, forKey: .autoPay) ?? false
        createdAt = try Self.decodeDate(container, key: .createdAt)
        updatedAt = try Self.decodeDate(container, key: .updatedAt)
    }

    init(
        id: String,
        userId: String,
        name: String,
        payee: String,
        amount: Double,
        currency: String = "USD",
        category: String,
        dueDate: Date,
        status: BillStatus,
        recurrence: BillRecurrence,
        notes: String?,
        paidAt: Date?,
        autoPay: Bool = false,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.payee = payee
        self.amount = amount
        self.currency = currency
        self.category = category
        self.dueDate = dueDate
        self.status = status
        self.recurrence = recurrence
        self.notes = notes
        self.paidAt = paidAt
        self.autoPay = autoPay
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var amountFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: amount)) ?? String(format: "$%.2f", amount)
    }

    var isPaid: Bool {
        status == .paid
    }

    var isOverdue: Bool {
        !isPaid && status != .cancelled && dueDate < Calendar.current.startOfDay(for: Date())
    }

    private static func decodeDate(_ container: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) throws -> Date? {
        guard let value = try container.decodeIfPresent(String.self, forKey: key) else {
            return nil
        }

        if let date = ISO8601DateFormatter().date(from: value) {
            return date
        }

        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)
    }
}

struct BillInsert: Codable {
    let userId: String
    let name: String
    let payee: String
    let amount: Double
    let currency: String
    let category: String
    let dueDate: String
    let status: String
    let recurrence: String
    let notes: String?
    let autoPay: Bool

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case name
        case payee
        case amount
        case currency
        case category
        case dueDate = "due_date"
        case status
        case recurrence
        case notes
        case autoPay = "auto_pay"
    }
}

struct BillStatusUpdate: Codable {
    let status: String
    let paidAt: String?

    enum CodingKeys: String, CodingKey {
        case status
        case paidAt = "paid_at"
    }
}

final class BillRepository {
    private let supabase = SupabaseClientManager.shared.client

    func fetchBills() async throws -> [Bill] {
        guard let userId = supabase.auth.currentSession?.user.id.uuidString else {
            throw AuthError.notAuthenticated
        }

        let response = try await supabase
            .from("bills")
            .select("*")
            .eq("user_id", value: userId)
            .order("due_date", ascending: true)
            .execute()

        return try JSONDecoder().decode([Bill].self, from: response.data)
    }

    func createBill(
        name: String,
        payee: String,
        amount: Double,
        category: String,
        dueDate: Date,
        recurrence: BillRecurrence,
        notes: String?
    ) async throws -> Bill {
        guard let userId = supabase.auth.currentSession?.user.id.uuidString else {
            throw AuthError.notAuthenticated
        }

        let insert = BillInsert(
            userId: userId,
            name: name,
            payee: payee,
            amount: amount,
            currency: "USD",
            category: category,
            dueDate: dueDate.dateOnlyString,
            status: "upcoming",
            recurrence: recurrence.rawValue,
            notes: notes,
            autoPay: false
        )

        let response = try await supabase
            .from("bills")
            .insert(insert)
            .select()
            .single()
            .execute()

        return try JSONDecoder().decode(Bill.self, from: response.data)
    }

    func markBillPaid(id: String) async throws -> Bill {
        let update = BillStatusUpdate(status: "paid", paidAt: Date().iso8601String)

        let response = try await supabase
            .from("bills")
            .update(update)
            .eq("id", value: id)
            .select()
            .single()
            .execute()

        return try JSONDecoder().decode(Bill.self, from: response.data)
    }

    func deleteBill(id: String) async throws {
        try await supabase
            .from("bills")
            .delete()
            .eq("id", value: id)
            .execute()
    }
}

private extension Date {
    var dateOnlyString: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
}
