//
//  Aircraft.swift
//  Opsight
//
//  Created by toño on 25/10/25.
//

import Foundation

struct Aircraft: Identifiable, Codable {
    let id: UUID
    let tailNumber: String?
    let model: String?
    let capacity: Int?
    let notes: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case tailNumber = "tail_number"
        case model
        case capacity
        case notes
        case createdAt = "created_at"
    }
    
    init(id: UUID = UUID(), tailNumber: String? = nil, model: String? = nil, capacity: Int? = nil, notes: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.tailNumber = tailNumber
        self.model = model
        self.capacity = capacity
        self.notes = notes
        self.createdAt = createdAt
    }
}
