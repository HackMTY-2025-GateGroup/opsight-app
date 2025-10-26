//
//  WasteRecord.swift
//  Opsight
//

import Foundation

/// Records waste from returned carts and expired products
/// Critical for tracking efficiency and reducing losses
struct WasteRecord: Identifiable, Codable {
    let id: UUID
    let productId: UUID
    let batchId: UUID?
    let quantity: Int
    let wasteReason: WasteReason
    let source: WasteSource
    let flightNumber: String?
    let recordedDate: Date
    let recordedBy: String?
    let estimatedValue: Double?
    let fillLevel: Double?  // For opened beverages (0.0 to 1.0)
    let notes: String?
    let imageUrl: String?  // Optional photo documentation

    // Extended properties
    var product: Product?
    var batch: ProductBatch?

    enum CodingKeys: String, CodingKey {
        case id
        case productId = "product_id"
        case batchId = "batch_id"
        case quantity
        case wasteReason = "waste_reason"
        case source
        case flightNumber = "flight_number"
        case recordedDate = "recorded_date"
        case recordedBy = "recorded_by"
        case estimatedValue = "estimated_value"
        case fillLevel = "fill_level"
        case notes
        case imageUrl = "image_url"
    }

    init(
        id: UUID = UUID(),
        productId: UUID,
        batchId: UUID? = nil,
        quantity: Int,
        wasteReason: WasteReason,
        source: WasteSource,
        flightNumber: String? = nil,
        recordedDate: Date = Date(),
        recordedBy: String? = nil,
        estimatedValue: Double? = nil,
        fillLevel: Double? = nil,
        notes: String? = nil,
        imageUrl: String? = nil
    ) {
        self.id = id
        self.productId = productId
        self.batchId = batchId
        self.quantity = quantity
        self.wasteReason = wasteReason
        self.source = source
        self.flightNumber = flightNumber
        self.recordedDate = recordedDate
        self.recordedBy = recordedBy
        self.estimatedValue = estimatedValue
        self.fillLevel = fillLevel
        self.notes = notes
        self.imageUrl = imageUrl
    }

    /// Human-readable description of the waste
    var wasteDescription: String {
        var desc = "\(quantity) × \(product?.name ?? "Unknown")"
        if let fillLevel = fillLevel, fillLevel < 1.0 {
            desc += " (\(Int(fillLevel * 100))% full)"
        }
        return desc
    }

    /// Whether this waste could have been prevented
    var isPreventable: Bool {
        switch wasteReason {
        case .expired, .overstock, .poorQuality:
            return true
        case .opened, .damaged, .spilled, .contaminated:
            return false
        case .other:
            return false
        }
    }
}

enum WasteReason: String, Codable, CaseIterable {
    case expired = "expired"
    case opened = "opened"  // Opened beverage/food - per 50% rule
    case damaged = "damaged"
    case spilled = "spilled"
    case contaminated = "contaminated"
    case overstock = "overstock"
    case poorQuality = "poor_quality"
    case other = "other"

    var displayName: String {
        switch self {
        case .expired: return "Expired"
        case .opened: return "Opened (>50% rule)"
        case .damaged: return "Damaged"
        case .spilled: return "Spilled"
        case .contaminated: return "Contaminated"
        case .overstock: return "Overstock"
        case .poorQuality: return "Poor Quality"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .expired: return "calendar.badge.exclamationmark"
        case .opened: return "bottle.fill"
        case .damaged: return "exclamationmark.triangle.fill"
        case .spilled: return "drop.fill"
        case .contaminated: return "allergens"
        case .overstock: return "cube.box.fill"
        case .poorQuality: return "xmark.seal.fill"
        case .other: return "questionmark.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .expired: return "red"
        case .opened: return "orange"
        case .damaged: return "red"
        case .spilled: return "blue"
        case .contaminated: return "purple"
        case .overstock: return "yellow"
        case .poorQuality: return "orange"
        case .other: return "gray"
        }
    }
}

enum WasteSource: String, Codable {
    case returnedFromFlight = "returned_from_flight"
    case warehouse = "warehouse"
    case receiving = "receiving"
    case cartPrep = "cart_prep"

    var displayName: String {
        switch self {
        case .returnedFromFlight: return "Returned from Flight"
        case .warehouse: return "Warehouse Storage"
        case .receiving: return "Receiving Inspection"
        case .cartPrep: return "Cart Preparation"
        }
    }

    var icon: String {
        switch self {
        case .returnedFromFlight: return "airplane.arrival"
        case .warehouse: return "building.2.fill"
        case .receiving: return "shippingbox.fill"
        case .cartPrep: return "cart.fill"
        }
    }
}

/// Aggregated waste statistics
struct WasteStats {
    let totalWasteRecords: Int
    let totalQuantityWasted: Int
    let totalValueLost: Double
    let topWasteReasons: [(WasteReason, Int)]
    let preventableWastePercentage: Double
    let wasteByProduct: [(productName: String, quantity: Int)]

    var formattedValueLost: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: totalValueLost)) ?? "$0"
    }
}
