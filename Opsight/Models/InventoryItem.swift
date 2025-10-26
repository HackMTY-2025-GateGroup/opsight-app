//
//  InventoryItem.swift
//  Opsight
//
//  Created by toño on 25/10/25.
//

import Foundation

struct InventoryItem: Identifiable, Codable {
    let id: UUID
    let inventoryId: UUID
    let productId: UUID?
    let batchId: String?
    var quantity: Int
    var reserved: Int
    let minStock: Int
    let maxStock: Int
    let expiryDate: Date?
    let storageTempCelsius: Double?
    let cvMetadata: CVMetadata?
    let lastTempUpdatedAt: Date?
    let createdAt: Date
    let updatedAt: Date
    
    // Extended properties
    var product: Product?
    
    enum CodingKeys: String, CodingKey {
        case id
        case inventoryId = "inventory_id"
        case productId = "product_id"
        case batchId = "batch_id"
        case quantity
        case reserved
        case minStock = "min_stock"
        case maxStock = "max_stock"
        case expiryDate = "expiry_date"
        case storageTempCelsius = "storage_temp_celsius"
        case cvMetadata = "cv_metadata"
        case lastTempUpdatedAt = "last_temp_updated_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(id: UUID = UUID(), inventoryId: UUID, productId: UUID? = nil, batchId: String? = nil, quantity: Int = 0, reserved: Int = 0, minStock: Int = 0, maxStock: Int = 0, expiryDate: Date? = nil, storageTempCelsius: Double? = nil, cvMetadata: CVMetadata? = nil, lastTempUpdatedAt: Date? = nil, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.inventoryId = inventoryId
        self.productId = productId
        self.batchId = batchId
        self.quantity = quantity
        self.reserved = reserved
        self.minStock = minStock
        self.maxStock = maxStock
        self.expiryDate = expiryDate
        self.storageTempCelsius = storageTempCelsius
        self.cvMetadata = cvMetadata
        self.lastTempUpdatedAt = lastTempUpdatedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var availableQuantity: Int {
        quantity - reserved
    }
    
    var stockStatus: StockStatus {
        if quantity <= minStock {
            return .low
        } else if quantity >= maxStock {
            return .high
        } else {
            return .normal
        }
    }
    
    var expiryStatus: ExpiryStatus? {
        guard let expiryDate = expiryDate else { return nil }
        
        let daysUntilExpiry = Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0
        
        if daysUntilExpiry < 0 {
            return .expired
        } else if daysUntilExpiry <= 2 {
            return .critical
        } else if daysUntilExpiry <= 7 {
            return .warning
        } else {
            return .good
        }
    }
    
    var daysUntilExpiry: Int? {
        guard let expiryDate = expiryDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day
    }
}

enum StockStatus {
    case low
    case normal
    case high
    
    var color: String {
        switch self {
        case .low: return "red"
        case .normal: return "green"
        case .high: return "orange"
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "exclamationmark.triangle.fill"
        case .normal: return "checkmark.circle.fill"
        case .high: return "arrow.up.circle.fill"
        }
    }
}

enum ExpiryStatus {
    case expired
    case critical
    case warning
    case good
    
    var color: String {
        switch self {
        case .expired: return "red"
        case .critical: return "red"
        case .warning: return "orange"
        case .good: return "green"
        }
    }
    
    var icon: String {
        switch self {
        case .expired: return "xmark.circle.fill"
        case .critical: return "exclamationmark.triangle.fill"
        case .warning: return "exclamationmark.circle.fill"
        case .good: return "checkmark.circle.fill"
        }
    }
    
    var message: String {
        switch self {
        case .expired: return "Expired"
        case .critical: return "Expires in 2 days"
        case .warning: return "Expires in 7 days"
        case .good: return "Good"
        }
    }
}

struct CVMetadata: Codable {
    let detectionConfidence: Double?
    let boundingBox: BoundingBox?
    let lastScannedAt: Date?
    let fillLevel: Double? // For bottles
    let classification: String?
    
    enum CodingKeys: String, CodingKey {
        case detectionConfidence = "detection_confidence"
        case boundingBox = "bounding_box"
        case lastScannedAt = "last_scanned_at"
        case fillLevel = "fill_level"
        case classification
    }
}

struct BoundingBox: Codable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
}
