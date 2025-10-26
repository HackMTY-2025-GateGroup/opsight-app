//
//  ExpiryAlert.swift
//  Opsight
//
//  Created by toño on 25/10/25.
//

import Foundation

struct ExpiryAlert: Identifiable, Codable {
    let id: UUID
    let itemId: UUID?
    let inventoryId: UUID?
    let expiryDate: Date
    let level: AlertLevel
    let message: String?
    var acknowledged: Bool
    let acknowledgedBy: UUID?
    let createdAt: Date
    
    // Extended properties
    var item: InventoryItem?
    var acknowledger: Profile?
    
    enum CodingKeys: String, CodingKey {
        case id
        case itemId = "item_id"
        case inventoryId = "inventory_id"
        case expiryDate = "expiry_date"
        case level
        case message
        case acknowledged
        case acknowledgedBy = "acknowledged_by"
        case createdAt = "created_at"
    }
}

enum AlertLevel: String, Codable, CaseIterable {
    case info = "info"
    case warning = "warning"
    case critical = "critical"
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var color: String {
        switch self {
        case .info: return "blue"
        case .warning: return "orange"
        case .critical: return "red"
        }
    }
    
    var icon: String {
        switch self {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }
}
