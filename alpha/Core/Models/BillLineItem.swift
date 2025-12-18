//
//  BillLineItem.swift
//  alpha
//
//  Created by Claude Code on 12/18/25.
//

import Foundation

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
