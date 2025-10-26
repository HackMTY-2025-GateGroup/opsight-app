//
//  ProductBatch.swift
//  Opsight
//
//  Created by Claude on 25/10/25.
//

import Foundation

/// Represents a batch/lot of products received in the warehouse
/// All products in a batch share the same expiration date
struct ProductBatch: Identifiable, Codable {
    let id: UUID
    let productId: UUID
    let batchNumber: String
    let expirationDate: Date
    let receivedDate: Date
    var quantityReceived: Int
    var quantityRemaining: Int
    var quantityReserved: Int
    let supplierInfo: String?
    let notes: String?

    // Extended properties
    var product: Product?

    enum CodingKeys: String, CodingKey {
        case id
        case productId = "product_id"
        case batchNumber = "batch_number"
        case expirationDate = "expiration_date"
        case receivedDate = "received_date"
        case quantityReceived = "quantity_received"
        case quantityRemaining = "quantity_remaining"
        case quantityReserved = "quantity_reserved"
        case supplierInfo = "supplier_info"
        case notes
    }

    init(
        id: UUID = UUID(),
        productId: UUID,
        batchNumber: String,
        expirationDate: Date,
        receivedDate: Date = Date(),
        quantityReceived: Int,
        quantityRemaining: Int? = nil,
        quantityReserved: Int = 0,
        supplierInfo: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.productId = productId
        self.batchNumber = batchNumber
        self.expirationDate = expirationDate
        self.receivedDate = receivedDate
        self.quantityReceived = quantityReceived
        self.quantityRemaining = quantityRemaining ?? quantityReceived
        self.quantityReserved = quantityReserved
        self.supplierInfo = supplierInfo
        self.notes = notes
    }

    /// Available quantity that can be used for cart loading
    var availableQuantity: Int {
        quantityRemaining - quantityReserved
    }

    /// Days until expiration
    var daysUntilExpiry: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0
    }

    /// Expiration status for visual indicators
    var expiryStatus: ExpiryStatus {
        let days = daysUntilExpiry

        if days < 0 {
            return .expired
        } else if days <= 2 {
            return .critical
        } else if days <= 5 {
            return .warning  // 5-day margin per requirements
        } else {
            return .good
        }
    }

    /// Formatted expiration date string for worker-friendly display
    var formattedExpirationDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: expirationDate)
    }

    /// Priority for FEFO (First Expire First Out) sorting
    var fefoScore: Int {
        // Lower score = higher priority (expires sooner)
        return daysUntilExpiry
    }

    /// Whether this batch should be used based on expiration
    var shouldUse: Bool {
        daysUntilExpiry >= 0 && daysUntilExpiry <= 30
    }

    /// Whether this batch is critical and needs immediate use
    var isCritical: Bool {
        daysUntilExpiry <= 5 && daysUntilExpiry >= 0
    }
}
