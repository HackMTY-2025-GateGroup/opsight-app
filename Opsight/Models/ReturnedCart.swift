//
//  ReturnedCart.swift
//  Opsight
//

import Foundation

/// Represents a cart returned from an aircraft after flight
/// Contains mixed inventory: warehouse items + returned aircraft items
struct ReturnedCart: Identifiable, Codable {
    let id: UUID
    let cartId: UUID
    let flightNumber: String
    let returnedDate: Date
    let processedDate: Date?
    let processedBy: String?
    let returnedItems: [ReturnedItem]
    let status: ReturnStatus
    let notes: String?

    // Extended properties
    var cart: Trolley?

    enum CodingKeys: String, CodingKey {
        case id
        case cartId = "cart_id"
        case flightNumber = "flight_number"
        case returnedDate = "returned_date"
        case processedDate = "processed_date"
        case processedBy = "processed_by"
        case returnedItems = "returned_items"
        case status
        case notes
    }

    init(
        id: UUID = UUID(),
        cartId: UUID,
        flightNumber: String,
        returnedDate: Date = Date(),
        processedDate: Date? = nil,
        processedBy: String? = nil,
        returnedItems: [ReturnedItem] = [],
        status: ReturnStatus = .pending,
        notes: String? = nil
    ) {
        self.id = id
        self.cartId = cartId
        self.flightNumber = flightNumber
        self.returnedDate = returnedDate
        self.processedDate = processedDate
        self.processedBy = processedBy
        self.returnedItems = returnedItems
        self.status = status
        self.notes = notes
    }

    /// Total items returned
    var totalItemsReturned: Int {
        returnedItems.reduce(0) { $0 + $1.quantity }
    }

    /// Items that can be restocked
    var restockableItems: [ReturnedItem] {
        returnedItems.filter { $0.condition == .unopened }
    }

    /// Items that must be disposed
    var wasteItems: [ReturnedItem] {
        returnedItems.filter { $0.condition != .unopened }
    }

    /// Total waste value
    var estimatedWasteValue: Double {
        wasteItems.reduce(0.0) { total, item in
            total + (item.estimatedValue ?? 0.0)
        }
    }

    /// Whether this cart needs urgent processing
    var needsUrgentProcessing: Bool {
        let hoursSinceReturn = Calendar.current.dateComponents([.hour], from: returnedDate, to: Date()).hour ?? 0
        return hoursSinceReturn >= 2 || returnedItems.contains { $0.isPerishable }
    }
}

/// Individual item returned from aircraft
struct ReturnedItem: Identifiable, Codable {
    let id: UUID
    let productId: UUID
    let batchId: UUID?
    let quantity: Int
    let condition: ItemCondition
    let fillLevel: Double?  // For beverages: 0.0 to 1.0
    let isPerishable: Bool
    let estimatedValue: Double?
    let notes: String?

    // Extended properties
    var product: Product?
    var batch: ProductBatch?

    enum CodingKeys: String, CodingKey {
        case id
        case productId = "product_id"
        case batchId = "batch_id"
        case quantity
        case condition
        case fillLevel = "fill_level"
        case isPerishable = "is_perishable"
        case estimatedValue = "estimated_value"
        case notes
    }

    init(
        id: UUID = UUID(),
        productId: UUID,
        batchId: UUID? = nil,
        quantity: Int,
        condition: ItemCondition,
        fillLevel: Double? = nil,
        isPerishable: Bool = false,
        estimatedValue: Double? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.productId = productId
        self.batchId = batchId
        self.quantity = quantity
        self.condition = condition
        self.fillLevel = fillLevel
        self.isPerishable = isPerishable
        self.estimatedValue = estimatedValue
        self.notes = notes
    }

    /// Disposition recommendation based on 50% rule
    var dispositionRecommendation: Disposition {
        switch condition {
        case .unopened:
            return .restock
        case .opened:
            if let fill = fillLevel {
                return fill >= 0.5 ? .restock : .dispose
            }
            return .dispose
        case .damaged, .expired:
            return .dispose
        }
    }

    /// Icon representing the item condition
    var conditionIcon: String {
        condition.icon
    }

    /// Color for the condition status
    var conditionColor: String {
        condition.color
    }
}

enum ReturnStatus: String, Codable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case partiallyProcessed = "partially_processed"

    var displayName: String {
        switch self {
        case .pending: return "Pending Processing"
        case .processing: return "Processing"
        case .completed: return "Completed"
        case .partiallyProcessed: return "Partially Processed"
        }
    }

    var icon: String {
        switch self {
        case .pending: return "clock.fill"
        case .processing: return "gearshape.fill"
        case .completed: return "checkmark.circle.fill"
        case .partiallyProcessed: return "circle.lefthalf.filled"
        }
    }

    var color: String {
        switch self {
        case .pending: return "orange"
        case .processing: return "blue"
        case .completed: return "green"
        case .partiallyProcessed: return "yellow"
        }
    }
}

enum ItemCondition: String, Codable {
    case unopened = "unopened"
    case opened = "opened"
    case damaged = "damaged"
    case expired = "expired"

    var displayName: String {
        switch self {
        case .unopened: return "Unopened"
        case .opened: return "Opened"
        case .damaged: return "Damaged"
        case .expired: return "Expired"
        }
    }

    var icon: String {
        switch self {
        case .unopened: return "checkmark.seal.fill"
        case .opened: return "seal.fill"
        case .damaged: return "exclamationmark.triangle.fill"
        case .expired: return "calendar.badge.exclamationmark"
        }
    }

    var color: String {
        switch self {
        case .unopened: return "green"
        case .opened: return "orange"
        case .damaged: return "red"
        case .expired: return "red"
        }
    }
}

enum Disposition: String {
    case restock = "restock"
    case dispose = "dispose"
    case inspect = "inspect"

    var displayName: String {
        switch self {
        case .restock: return "Restock to Inventory"
        case .dispose: return "Dispose as Waste"
        case .inspect: return "Needs Inspection"
        }
    }

    var icon: String {
        switch self {
        case .restock: return "arrow.uturn.backward.circle.fill"
        case .dispose: return "trash.fill"
        case .inspect: return "magnifyingglass.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .restock: return "green"
        case .dispose: return "red"
        case .inspect: return "yellow"
        }
    }
}
