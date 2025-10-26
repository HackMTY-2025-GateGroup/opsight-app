//
//  LoadingSession.swift
//  Opsight
//
//  Created by toño on 25/10/25.
//

import Foundation

/// Represents a cart loading session with manifest and results
struct LoadingSession: Identifiable, Codable {
    let id: UUID
    let manifest: CartManifest
    let scannedAt: Date
    var detectedItems: [MealItem]
    var status: SessionStatus
    var accuracy: Double
    var missingItems: [MealItem]
    var extraItems: [MealItem]

    init(
        id: UUID = UUID(),
        manifest: CartManifest,
        scannedAt: Date = Date(),
        detectedItems: [MealItem] = [],
        status: SessionStatus = .inProgress
    ) {
        self.id = id
        self.manifest = manifest
        self.scannedAt = scannedAt
        self.detectedItems = detectedItems
        self.status = status

        // Calculate accuracy and mismatches
        let expected = manifest.expectedItems
        let detected = detectedItems

        // Find missing items (in expected but not detected)
        self.missingItems = expected.filter { expectedItem in
            let detectedQuantity = detected.first(where: { $0.name == expectedItem.name })?.quantity ?? 0
            return detectedQuantity < expectedItem.quantity
        }.map { item in
            let detectedQty = detected.first(where: { $0.name == item.name })?.quantity ?? 0
            return MealItem(
                name: item.name,
                category: item.category,
                quantity: item.quantity - detectedQty
            )
        }

        // Find extra items (detected but not expected or over-quantity)
        self.extraItems = detected.filter { detectedItem in
            let expectedQuantity = expected.first(where: { $0.name == detectedItem.name })?.quantity ?? 0
            return detectedItem.quantity > expectedQuantity
        }.map { item in
            let expectedQty = expected.first(where: { $0.name == item.name })?.quantity ?? 0
            return MealItem(
                name: item.name,
                category: item.category,
                quantity: item.quantity - expectedQty
            )
        }

        // Calculate accuracy as percentage of correctly loaded items
        let totalExpected = expected.reduce(0) { $0 + $1.quantity }
        let totalMissing = missingItems.reduce(0) { $0 + $1.quantity }
        let totalExtra = extraItems.reduce(0) { $0 + $1.quantity }

        if totalExpected > 0 {
            self.accuracy = Double(totalExpected - totalMissing - totalExtra) / Double(totalExpected)
            self.accuracy = max(0, min(1, self.accuracy))
        } else {
            self.accuracy = 1.0
        }
    }

    enum SessionStatus: String, Codable {
        case inProgress = "In Progress"
        case completed = "Completed"
        case cancelled = "Cancelled"
    }
}
