//
//  ProductUsageHistory.swift
//  Opsight
//

import Foundation

/// Tracks historical consumption patterns for products
/// Helps predict which products are consumed more and optimize inventory
struct ProductUsageHistory: Identifiable, Codable {
    let id: UUID
    let productId: UUID
    let flightNumber: String?
    let route: String?
    let date: Date
    let quantityExpected: Int
    let quantityUsed: Int
    let quantityReturned: Int
    let utilizationRate: Double  // Percentage actually consumed
    let passengerCount: Int?
    let classOfService: String?  // Economy, Business, First
    let notes: String?

    // Extended properties
    var product: Product?

    enum CodingKeys: String, CodingKey {
        case id
        case productId = "product_id"
        case flightNumber = "flight_number"
        case route
        case date
        case quantityExpected = "quantity_expected"
        case quantityUsed = "quantity_used"
        case quantityReturned = "quantity_returned"
        case utilizationRate = "utilization_rate"
        case passengerCount = "passenger_count"
        case classOfService = "class_of_service"
        case notes
    }

    init(
        id: UUID = UUID(),
        productId: UUID,
        flightNumber: String? = nil,
        route: String? = nil,
        date: Date = Date(),
        quantityExpected: Int,
        quantityUsed: Int,
        quantityReturned: Int,
        passengerCount: Int? = nil,
        classOfService: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.productId = productId
        self.flightNumber = flightNumber
        self.route = route
        self.date = date
        self.quantityExpected = quantityExpected
        self.quantityUsed = quantityUsed
        self.quantityReturned = quantityReturned
        self.utilizationRate = quantityExpected > 0 ? Double(quantityUsed) / Double(quantityExpected) : 0.0
        self.passengerCount = passengerCount
        self.classOfService = classOfService
        self.notes = notes
    }

    /// Wasted quantity that was sent but not consumed
    var wasteQuantity: Int {
        quantityExpected - quantityUsed - quantityReturned
    }

    /// Whether this product performed well (high utilization)
    var isHighPerformer: Bool {
        utilizationRate >= 0.8
    }

    /// Whether this product should be reduced on future flights
    var isLowPerformer: Bool {
        utilizationRate <= 0.3
    }
}

/// Aggregated usage statistics for a product
struct ProductUsageStats: Identifiable {
    let id: UUID
    let productId: UUID
    let productName: String
    let totalFlights: Int
    let averageUtilization: Double
    let totalExpected: Int
    let totalUsed: Int
    let totalWasted: Int
    let trend: UsageTrend

    enum UsageTrend {
        case increasing
        case stable
        case decreasing

        var icon: String {
            switch self {
            case .increasing: return "arrow.up.circle.fill"
            case .stable: return "minus.circle.fill"
            case .decreasing: return "arrow.down.circle.fill"
            }
        }

        var color: String {
            switch self {
            case .increasing: return "green"
            case .stable: return "blue"
            case .decreasing: return "orange"
            }
        }
    }

    /// Recommendation based on historical data
    var recommendation: String {
        if averageUtilization >= 0.9 {
            return "Consider increasing stock - high demand"
        } else if averageUtilization >= 0.7 {
            return "Optimal performance"
        } else if averageUtilization >= 0.4 {
            return "Consider reducing quantity"
        } else {
            return "Low utilization - review necessity"
        }
    }
}
