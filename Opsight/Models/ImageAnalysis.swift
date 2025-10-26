//
//  ImageAnalysis.swift
//  Opsight
//
//  Created by toño on 25/10/25.
//

import Foundation

struct ImageAnalysis: Identifiable, Codable {
    let id: UUID
    let inventoryId: UUID?
    let trolleyId: UUID?
    let imagePath: String?
    let analysisResult: AnalysisResult?
    let confidence: Double?
    let modelVersion: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case inventoryId = "inventory_id"
        case trolleyId = "trolley_id"
        case imagePath = "image_path"
        case analysisResult = "analysis_result"
        case confidence
        case modelVersion = "model_version"
        case createdAt = "created_at"
    }
}

struct AnalysisResult: Codable {
    let detections: [ImageDetection]?
    let occupancy: Double?
    let note: String?
    let missingItems: [String]?
    let extraItems: [String]?
    let bottleAnalysis: [BottleAnalysis]?
}

struct ImageDetection: Codable, Identifiable {
    let id: UUID
    let productId: UUID?
    let productName: String
    let category: String?
    let confidence: Double
    let boundingBox: BoundingBox
    let quantity: Int
    let status: DetectionStatus
    
    enum CodingKeys: String, CodingKey {
        case id
        case productId = "product_id"
        case productName = "product_name"
        case category
        case confidence
        case boundingBox = "bounding_box"
        case quantity
        case status
    }
    
    init(id: UUID = UUID(), productId: UUID? = nil, productName: String, category: String? = nil, confidence: Double, boundingBox: BoundingBox, quantity: Int = 1, status: DetectionStatus = .correct) {
        self.id = id
        self.productId = productId
        self.productName = productName
        self.category = category
        self.confidence = confidence
        self.boundingBox = boundingBox
        self.quantity = quantity
        self.status = status
    }
}

enum DetectionStatus: String, Codable {
    case correct = "correct"
    case warning = "warning"
    case error = "error"
    case missing = "missing"
    case extra = "extra"
    
    var color: String {
        switch self {
        case .correct: return "green"
        case .warning: return "orange"
        case .error: return "red"
        case .missing: return "red"
        case .extra: return "orange"
        }
    }
    
    var icon: String {
        switch self {
        case .correct: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        case .missing: return "minus.circle.fill"
        case .extra: return "plus.circle.fill"
        }
    }
}

struct BottleAnalysis: Codable, Identifiable {
    let id: UUID
    let productId: UUID?
    let productName: String
    let fillLevel: Double // 0.0 to 1.0
    let recommendedAction: BottleAction
    let airlineRule: String?
    let confidence: Double
    
    enum CodingKeys: String, CodingKey {
        case id
        case productId = "product_id"
        case productName = "product_name"
        case fillLevel = "fill_level"
        case recommendedAction = "recommended_action"
        case airlineRule = "airline_rule"
        case confidence
    }
    
    init(id: UUID = UUID(), productId: UUID? = nil, productName: String, fillLevel: Double, recommendedAction: BottleAction, airlineRule: String? = nil, confidence: Double) {
        self.id = id
        self.productId = productId
        self.productName = productName
        self.fillLevel = fillLevel
        self.recommendedAction = recommendedAction
        self.airlineRule = airlineRule
        self.confidence = confidence
    }
}

enum BottleAction: String, Codable {
    case keepFlying = "keep_flying"
    case discard = "discard"
    case combine = "combine"
    
    var displayName: String {
        switch self {
        case .keepFlying: return "Keep Flying"
        case .discard: return "Discard"
        case .combine: return "Combine"
        }
    }
    
    var color: String {
        switch self {
        case .keepFlying: return "green"
        case .discard: return "red"
        case .combine: return "orange"
        }
    }
    
    var icon: String {
        switch self {
        case .keepFlying: return "checkmark.circle.fill"
        case .discard: return "trash.fill"
        case .combine: return "arrow.triangle.merge"
        }
    }
}
