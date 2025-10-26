//
//  Product.swift
//  Opsight
//
//  Created by toño on 25/10/25.
//

import Foundation

struct Product: Identifiable, Codable {
    let id: UUID
    let sku: String?
    let name: String
    let description: String?
    let category: String?
    let perishable: Bool
    let shelfLifeDays: Int?
    let minStock: Int
    let maxStock: Int
    let dimensions: ProductDimensions?
    let metadata: [String: AnyCodable]?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case sku
        case name
        case description
        case category
        case perishable
        case shelfLifeDays = "shelf_life_days"
        case minStock = "min_stock"
        case maxStock = "max_stock"
        case dimensions
        case metadata
        case createdAt = "created_at"
    }
    
    init(id: UUID = UUID(), sku: String? = nil, name: String, description: String? = nil, category: String? = nil, perishable: Bool = false, shelfLifeDays: Int? = nil, minStock: Int = 0, maxStock: Int = 0, dimensions: ProductDimensions? = nil, metadata: [String: AnyCodable]? = nil, createdAt: Date = Date()) {
        self.id = id
        self.sku = sku
        self.name = name
        self.description = description
        self.category = category
        self.perishable = perishable
        self.shelfLifeDays = shelfLifeDays
        self.minStock = minStock
        self.maxStock = maxStock
        self.dimensions = dimensions
        self.metadata = metadata
        self.createdAt = createdAt
    }
    
    var categoryIcon: String {
        guard let category = category?.lowercased() else {
            return "cube.box.fill"
        }
        
        switch category {
        case "beverage", "beverages": return "cup.and.saucer.fill"
        case "snack", "snacks": return "takeoutbag.and.cup.and.straw.fill"
        case "meal", "meals": return "fork.knife"
        case "duty-free": return "bag.fill"
        case "equipment", "cabin equipment": return "tray.fill"
        case "alcohol": return "wineglass.fill"
        default: return "cube.box.fill"
        }
    }
}

struct ProductDimensions: Codable {
    let widthCm: Double?
    let heightCm: Double?
    let depthCm: Double?
    
    enum CodingKeys: String, CodingKey {
        case widthCm = "width_cm"
        case heightCm = "height_cm"
        case depthCm = "depth_cm"
    }
}

// Helper for dynamic JSON
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}
