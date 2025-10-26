//
//  Trolley.swift
//  Opsight
//
//  Created by toño on 25/10/25.
//

import Foundation

struct Trolley: Identifiable, Codable {
    let id: UUID
    let code: String?
    let flightId: UUID?
    let status: TrolleyStatus
    let lastCheck: Date?
    let createdAt: Date
    
    // Extended properties
    var flight: Flight?
    var inventory: Inventory?
    
    enum CodingKeys: String, CodingKey {
        case id
        case code
        case flightId = "flight_id"
        case status
        case lastCheck = "last_check"
        case createdAt = "created_at"
    }
    
    init(id: UUID = UUID(), code: String? = nil, flightId: UUID? = nil, status: TrolleyStatus = .ready, lastCheck: Date? = nil, createdAt: Date = Date()) {
        self.id = id
        self.code = code
        self.flightId = flightId
        self.status = status
        self.lastCheck = lastCheck
        self.createdAt = createdAt
    }
}

enum TrolleyStatus: String, Codable, CaseIterable {
    case ready = "ready"
    case inFlight = "in-flight"
    case returned = "returned"
    case maintenance = "maintenance"
    
    var displayName: String {
        switch self {
        case .ready: return "Ready"
        case .inFlight: return "In Flight"
        case .returned: return "Returned"
        case .maintenance: return "Maintenance"
        }
    }
    
    var color: String {
        switch self {
        case .ready: return "green"
        case .inFlight: return "blue"
        case .returned: return "orange"
        case .maintenance: return "red"
        }
    }
    
    var icon: String {
        switch self {
        case .ready: return "checkmark.circle.fill"
        case .inFlight: return "airplane.circle.fill"
        case .returned: return "arrow.counterclockwise.circle.fill"
        case .maintenance: return "wrench.and.screwdriver.fill"
        }
    }
}
