//
//  InventoryMovement.swift
//  Opsight
//
//  Created by toño on 25/10/25.
//

import Foundation

struct InventoryMovement: Identifiable, Codable {
    let id: UUID
    let itemId: UUID?
    let inventoryId: UUID?
    let performedBy: UUID?
    let qtyChange: Int
    let movementType: MovementType
    let fromInventory: UUID?
    let toInventory: UUID?
    let flightId: UUID?
    let notes: String?
    let createdAt: Date
    
    // Extended properties
    var performer: Profile?
    var item: InventoryItem?
    
    enum CodingKeys: String, CodingKey {
        case id
        case itemId = "item_id"
        case inventoryId = "inventory_id"
        case performedBy = "performed_by"
        case qtyChange = "qty_change"
        case movementType = "movement_type"
        case fromInventory = "from_inventory"
        case toInventory = "to_inventory"
        case flightId = "flight_id"
        case notes
        case createdAt = "created_at"
    }
}

enum MovementType: String, Codable, CaseIterable {
    case `in` = "in"
    case out = "out"
    case transfer = "transfer"
    case adjustment = "adjustment"
    case waste = "waste"
    case replenishment = "replenishment"
    
    var displayName: String {
        switch self {
        case .in: return "Stock In"
        case .out: return "Stock Out"
        case .transfer: return "Transfer"
        case .adjustment: return "Adjustment"
        case .waste: return "Waste"
        case .replenishment: return "Replenishment"
        }
    }
    
    var icon: String {
        switch self {
        case .in: return "arrow.down.circle.fill"
        case .out: return "arrow.up.circle.fill"
        case .transfer: return "arrow.left.arrow.right.circle.fill"
        case .adjustment: return "slider.horizontal.3"
        case .waste: return "trash.fill"
        case .replenishment: return "arrow.clockwise.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .in: return "green"
        case .out: return "blue"
        case .transfer: return "purple"
        case .adjustment: return "orange"
        case .waste: return "red"
        case .replenishment: return "green"
        }
    }
}
