//
//  Inventory.swift
//  Opsight
//
//  Created by toño on 25/10/25.
//

import Foundation

struct Inventory: Identifiable, Codable {
    let id: UUID
    let locationType: LocationType
    let locationId: UUID?
    let name: String?
    let notes: String?
    let updatedAt: Date
    let createdAt: Date
    
    // Extended properties
    var items: [InventoryItem]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case locationType = "location_type"
        case locationId = "location_id"
        case name
        case notes
        case updatedAt = "updated_at"
        case createdAt = "created_at"
    }
    
    init(id: UUID = UUID(), locationType: LocationType, locationId: UUID? = nil, name: String? = nil, notes: String? = nil, updatedAt: Date = Date(), createdAt: Date = Date()) {
        self.id = id
        self.locationType = locationType
        self.locationId = locationId
        self.name = name
        self.notes = notes
        self.updatedAt = updatedAt
        self.createdAt = createdAt
    }
    
    var totalItems: Int {
        items?.reduce(0) { $0 + $1.quantity } ?? 0
    }
    
    var uniqueProducts: Int {
        items?.count ?? 0
    }
}

enum LocationType: String, Codable, CaseIterable {
    case general = "general"
    case trolley = "trolley"
    case flight = "flight"
    case lounge = "lounge"
    case aircraftStorage = "aircraft_storage"
    
    var displayName: String {
        switch self {
        case .general: return "General Storage"
        case .trolley: return "Trolley"
        case .flight: return "Flight"
        case .lounge: return "Lounge"
        case .aircraftStorage: return "Aircraft Storage"
        }
    }
    
    var icon: String {
        switch self {
        case .general: return "building.2.fill"
        case .trolley: return "cart.fill"
        case .flight: return "airplane"
        case .lounge: return "sofa.fill"
        case .aircraftStorage: return "airplane.departure"
        }
    }
}
