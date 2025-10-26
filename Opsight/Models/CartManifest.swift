//
//  CartManifest.swift
//  Opsight
//
//  Created by toño on 25/10/25.
//

import Foundation

/// Represents the expected contents of a cart for a specific flight
/// Includes client-specific requirements and batch assignments for FEFO compliance
struct CartManifest: Identifiable, Codable {
    let id: UUID
    let flightNumber: String
    let destination: String
    let aircraftType: String?
    let departureTime: Date
    let totalPassengers: Int
    let extraPassengers: Int?  // Previsto de pasajeros extra
    let expectedItems: [MealItem]
    let clientRequirements: ClientRequirements?
    let batchAssignments: [BatchAssignment]?  // FEFO-based batch selection
    let specialInstructions: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case flightNumber = "flight_number"
        case destination
        case aircraftType = "aircraft_type"
        case departureTime = "departure_time"
        case totalPassengers = "total_passengers"
        case extraPassengers = "extra_passengers"
        case expectedItems = "expected_items"
        case clientRequirements = "client_requirements"
        case batchAssignments = "batch_assignments"
        case specialInstructions = "special_instructions"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(
        id: UUID = UUID(),
        flightNumber: String,
        destination: String,
        aircraftType: String? = nil,
        departureTime: Date,
        totalPassengers: Int,
        extraPassengers: Int? = nil,
        expectedItems: [MealItem],
        clientRequirements: ClientRequirements? = nil,
        batchAssignments: [BatchAssignment]? = nil,
        specialInstructions: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.flightNumber = flightNumber
        self.destination = destination
        self.aircraftType = aircraftType
        self.departureTime = departureTime
        self.totalPassengers = totalPassengers
        self.extraPassengers = extraPassengers
        self.expectedItems = expectedItems
        self.clientRequirements = clientRequirements
        self.batchAssignments = batchAssignments
        self.specialInstructions = specialInstructions
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Total items expected on this cart
    var totalItems: Int {
        expectedItems.reduce(0) { $0 + $1.quantity }
    }

    /// Formatted flight route
    var route: String {
        destination
    }

    /// Time until departure
    var hoursUntilDeparture: Int {
        let components = Calendar.current.dateComponents([.hour], from: Date(), to: departureTime)
        return components.hour ?? 0
    }

    /// Whether this flight needs urgent preparation
    var isUrgent: Bool {
        hoursUntilDeparture <= 2
    }

    /// Adjusted passenger count including extras
    var adjustedPassengerCount: Int {
        totalPassengers + (extraPassengers ?? 0)
    }
}

/// Client-specific cart configuration requirements
/// Changes every 4 months based on consumer data
struct ClientRequirements: Codable {
    let clientName: String
    let effectiveDate: Date
    let expirationDate: Date?
    let categoryRequirements: [CategoryRequirement]
    let layoutInstructions: String?
    let qualityStandards: String?

    enum CodingKeys: String, CodingKey {
        case clientName = "client_name"
        case effectiveDate = "effective_date"
        case expirationDate = "expiration_date"
        case categoryRequirements = "category_requirements"
        case layoutInstructions = "layout_instructions"
        case qualityStandards = "quality_standards"
    }

    var isActive: Bool {
        let now = Date()
        if let expiration = expirationDate {
            return now >= effectiveDate && now <= expiration
        }
        return now >= effectiveDate
    }
}

/// Specific requirements for product categories
struct CategoryRequirement: Codable {
    let category: String  // e.g., "canned_goods", "snacks", "beverages"
    let minimumQuantity: Int?
    let maximumQuantity: Int?
    let arrangement: String?  // How to arrange in cart
    let notes: String?

    var displayName: String {
        category.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

/// Assignment of specific batches to fulfill manifest
/// Implements FEFO (First Expire First Out) logic
struct BatchAssignment: Identifiable, Codable {
    let id: UUID
    let productId: UUID
    let batchId: UUID
    let batchNumber: String
    let quantityAssigned: Int
    let expirationDate: Date
    let assignedDate: Date

    // Extended properties
    var product: Product?
    var batch: ProductBatch?

    enum CodingKeys: String, CodingKey {
        case id
        case productId = "product_id"
        case batchId = "batch_id"
        case batchNumber = "batch_number"
        case quantityAssigned = "quantity_assigned"
        case expirationDate = "expiration_date"
        case assignedDate = "assigned_date"
    }

    init(
        id: UUID = UUID(),
        productId: UUID,
        batchId: UUID,
        batchNumber: String,
        quantityAssigned: Int,
        expirationDate: Date,
        assignedDate: Date = Date()
    ) {
        self.id = id
        self.productId = productId
        self.batchId = batchId
        self.batchNumber = batchNumber
        self.quantityAssigned = quantityAssigned
        self.expirationDate = expirationDate
        self.assignedDate = assignedDate
    }

    /// Days until this batch expires
    var daysUntilExpiry: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0
    }

    /// Whether this batch is within acceptable expiration window
    var isWithinExpiryMargin: Bool {
        daysUntilExpiry >= 5  // 5-day margin per requirements
    }

    /// Visual indicator for expiration status
    var expiryStatusColor: String {
        if daysUntilExpiry < 5 {
            return "red"
        } else if daysUntilExpiry <= 7 {
            return "orange"
        } else {
            return "green"
        }
    }
}
