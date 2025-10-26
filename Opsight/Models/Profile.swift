//
//  Profile.swift
//  Opsight
//
//  Created by toño on 25/10/25.
//

import Foundation

struct Profile: Identifiable, Codable {
    let id: UUID
    let authId: UUID?
    let name: String?
    let email: String?
    let phone: String?
    let role: UserRole
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case authId = "auth_id"
        case name
        case email
        case phone
        case role
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum UserRole: String, Codable, CaseIterable {
    case admin = "admin"
    case inventoryManager = "inventory_manager"
    case aircraftManager = "aircraft_manager"
    case flightAttendant = "flight_attendant"
    
    var displayName: String {
        switch self {
        case .admin: return "Administrator"
        case .inventoryManager: return "Inventory Manager"
        case .aircraftManager: return "Aircraft Manager"
        case .flightAttendant: return "Flight Attendant"
        }
    }
    
    var icon: String {
        switch self {
        case .admin: return "person.badge.key.fill"
        case .inventoryManager: return "shippingbox.fill"
        case .aircraftManager: return "airplane"
        case .flightAttendant: return "person.fill"
        }
    }
}
