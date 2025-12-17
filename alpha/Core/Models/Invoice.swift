//
//  Invoice.swift
//  alpha
//
//  Created by Claude Code on 11/25/25.
//

import Foundation

enum InvoiceStatus: String, Codable {
    case draft = "DRAFT"
    case sent = "SENT"
    case paid = "PAID"
    case overdue = "OVERDUE"
    case cancelled = "CANCELLED"

    var displayName: String {
        switch self {
        case .draft:
            return "Draft"
        case .sent:
            return "Sent"
        case .paid:
            return "Paid"
        case .overdue:
            return "Overdue"
        case .cancelled:
            return "Cancelled"
        }
    }
}

struct Invoice: Codable, Identifiable {
    let id: String
    let organizationId: String?
    let clientId: String
    let projectId: String?
    let invoiceNumber: String
    let issueDate: Date
    let dueDate: Date
    let subtotal: Double
    let taxRate: Double?
    let taxAmount: Double?
    let total: Double
    let currency: String
    let status: InvoiceStatus
    let notes: String?
    let paidAt: Date?
    let createdAt: Date?
    let updatedAt: Date?

    // Populated by backend joins
    let client: Client?
    let project: Project?

    enum CodingKeys: String, CodingKey {
        case id
        case organizationId = "organization_id"
        case clientId = "client_id"
        case projectId = "project_id"
        case invoiceNumber = "invoice_number"
        case issueDate = "issue_date"
        case dueDate = "due_date"
        case subtotal
        case taxRate = "tax_rate"
        case taxAmount = "tax_amount"
        case total
        case currency
        case status
        case notes
        case paidAt = "paid_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case client
        case project
    }

    // Computed properties
    var totalFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: total)) ?? String(format: "$%.2f", total)
    }

    var isOverdue: Bool {
        guard status != .paid && status != .cancelled else { return false }
        return dueDate < Date()
    }

    var daysUntilDue: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: dueDate)
        return components.day ?? 0
    }
}

// MARK: - Preview Helpers
extension Invoice {
    static let preview = Invoice(
        id: "invoice_1",
        organizationId: "org_1",
        clientId: "client_1",
        projectId: "project_1",
        invoiceNumber: "INV-2025-001",
        issueDate: Date(),
        dueDate: Date().addingTimeInterval(60 * 60 * 24 * 30), // 30 days
        subtotal: 15000.00,
        taxRate: 0.0825,
        taxAmount: 1237.50,
        total: 16237.50,
        currency: "USD",
        status: .sent,
        notes: "Thank you for your business!",
        paidAt: nil,
        createdAt: Date(),
        updatedAt: Date(),
        client: .preview,
        project: .preview
    )
}
