//
//  TrolleyOcuppancyModel.swift
//  Opsight
//
//  Created by toño on 26/10/25.
//

import MLX
import MLXNN
import MLXOptimizers
import Foundation

// MARK: - Data Structures

/// Detection result from YOLO model
struct Detection {
    let className: String
    let confidence: Float
    let boundingBox: BoundingBox
    let frame: FrameInfo
    
    struct BoundingBox {
        let x: Float
        let y: Float
        let width: Float
        let height: Float
    }
    
    struct FrameInfo {
        let width: Float
        let height: Float
    }
}

/// Visual occupancy analysis result
struct VisualOccupancyResult {
    let finalScore: Float
    let category: OccupancyCategory
    let fillPercent: Float
    let snackPercent: Float
    let verticalScore: Float
    let fillLineScore: Float
    let detectionCount: Int
    let topRatio: Float
    let detail: String
}

enum OccupancyCategory: String, CaseIterable {
    case empty = "empty"
    case sparse = "sparse"
    case partial = "partial"
    case good = "good"
    case nearlyFull = "nearly_full"
    case full = "full"
}

/// Beverage classification types
enum BeverageType: String, CaseIterable {
    case can = "can"
    case bottleWater = "bottle_water"
    case juiceBox = "juice_box"
    case cookie = "cookie"
    case unknown = "unknown"
}

// MARK: - Core Model

/// Main trolley occupancy detection model
class TrolleyOccupancyModel {
    
    // MARK: - Configuration
    
    private let defaultConfidence: Float = 0.15
    private let defaultIoU: Float = 0.6
    private let defaultImageSize: Int = 960
    
    // MARK: - Detection Processing
    
    /// Process raw detections and normalize them
    func normalizeDetections(_ rawDetections: [Detection]) -> [Detection] {
        return rawDetections.map { detection in
            let normalizedClass = classifyDetection(detection)
            return Detection(
                className: normalizedClass.rawValue,
                confidence: detection.confidence,
                boundingBox: detection.boundingBox,
                frame: detection.frame
            )
        }
    }
    
    /// Classify detection based on class name and geometry
    func classifyDetection(_ detection: Detection) -> BeverageType {
        let rawClass = detection.className.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Direct keyword matching
        if rawClass.contains("cookie") || rawClass.contains("snack") || rawClass.contains("galleta") {
            return .cookie
        }
        if rawClass.contains("juice") || rawClass.contains("carton") || rawClass.contains("box") {
            return .juiceBox
        }
        if rawClass.contains("can") || rawClass.contains("lat") || rawClass.contains("cup") {
            return .can
        }
        if rawClass.contains("water") {
            return .bottleWater
        }
        if rawClass.contains("coke") || rawClass.contains("cola") {
            return .bottleWater
        }
        if rawClass.contains("bottle") {
            return classifyBeverageByGeometry(detection)
        }
        
        // Fallback to geometry-based classification
        return classifyBeverageByGeometry(detection)
    }
    
    /// Classify beverage type based on geometric features
    func classifyBeverageByGeometry(_ detection: Detection) -> BeverageType {
        let geometryFeatures = computeGeometryFeatures(detection)
        
        // Short + wide silhouettes behave like cans
        if (geometryFeatures.aspectRatio >= 0.78 && geometryFeatures.normalizedHeight <= 0.22) ||
           (geometryFeatures.normalizedHeight <= 0.14 && geometryFeatures.aspectRatio >= 0.7) {
            return .can
        }
        
        // Tall & slender -> bottled water profile
        if geometryFeatures.aspectRatio <= 0.52 || geometryFeatures.normalizedHeight >= 0.3 {
            return .bottleWater
        }
        
        // Medium rectangle occupying noticeable width → juice box/carton
        if (geometryFeatures.normalizedWidth >= 0.18 && geometryFeatures.aspectRatio >= 0.55) ||
           (geometryFeatures.areaRatio >= 0.02 && geometryFeatures.aspectRatio >= 0.55) {
            return .juiceBox
        }
        
        // Fallback: prefer bottled water for safety
        return .bottleWater
    }
    
    /// Compute geometric features from detection
    func computeGeometryFeatures(_ detection: Detection) -> GeometryFeatures {
        let bbox = detection.boundingBox
        let frame = detection.frame
        
        let aspectRatio = bbox.height > 0 ? bbox.width / bbox.height : 1.0
        let normalizedHeight = frame.height > 0 ? bbox.height / frame.height : 0.0
        let normalizedWidth = frame.width > 0 ? bbox.width / frame.width : 0.0
        let areaRatio = (frame.width > 0 && frame.height > 0) ?
            (bbox.width * bbox.height) / (frame.width * frame.height) : 0.0
        
        return GeometryFeatures(
            aspectRatio: aspectRatio,
            normalizedHeight: normalizedHeight,
            normalizedWidth: normalizedWidth,
            areaRatio: areaRatio
        )
    }
    
    struct GeometryFeatures {
        let aspectRatio: Float
        let normalizedHeight: Float
        let normalizedWidth: Float
        let areaRatio: Float
    }
    
    // MARK: - Visual Occupancy Analysis
    
    /// Estimate visual occupancy using heuristic analysis
    func estimateVisualOccupancyHeuristic(
        detections: [Detection],
        frameWidth: Float,
        frameHeight: Float
    ) -> VisualOccupancyResult {
        
        guard !detections.isEmpty else {
            return VisualOccupancyResult(
                finalScore: 0,
                category: .empty,
                fillPercent: 0,
                snackPercent: 0,
                verticalScore: 0,
                fillLineScore: 0,
                detectionCount: 0,
                topRatio: 0,
                detail: "No detections - empty tray"
            )
        }
        
        // Analyze detection distribution
        var topThird: Float = 0
        var middleThird: Float = 0
        var bottomThird: Float = 0
        var totalArea: Float = 0
        var snackArea: Float = 0
        var colorfulItems: Float = 0
        
        for detection in detections {
            let bbox = detection.boundingBox
            let area = bbox.width * bbox.height
            totalArea += area
            
            // Vertical distribution
            let centerY = bbox.y + bbox.height / 2
            if centerY < frameHeight * 0.33 {
                topThird += area
            } else if centerY < frameHeight * 0.66 {
                middleThird += area
            } else {
                bottomThird += area
            }
            
            // Snack detection heuristic
            let label = detection.className.lowercased()
            let isSnack = label.contains("cookie") || label.contains("snack") || label.contains("galleta")
            let isBottleOrCan = label.contains("bottle") || label.contains("water") ||
                              label.contains("can") || label.contains("juice")
            
            if isSnack { snackArea += area }
            if isBottleOrCan { colorfulItems += area }
        }
        
        // Calculate percentages
        let frameArea = frameWidth * frameHeight
        
        // Fill percent: how much area is occupied (boosted)
        let fillPercent = min(100, (totalArea / frameArea) * 100 * 1.8)
        
        // Snack percent: focused on identified snacks
        let snackPercent = snackArea > 0 ? min(100, (snackArea / frameArea) * 100 * 2.5) : 0
        
        // Product detection bonus
        let detectionBonus = min(10, Float(detections.count))
        
        // Vertical score: CRITICAL - where are items packed?
        var verticalScore: Float = 5
        var topRatio: Float = 0
        
        if topThird + middleThird + bottomThird > 0 {
            topRatio = topThird / (topThird + middleThird + bottomThird)
        }
        
        if topRatio > 0.5 {
            // Items packed at top = FULL
            verticalScore = 9.5
        } else if topRatio > 0.35 {
            // Mostly top with some middle
            verticalScore = 8
        } else if bottomThird > topThird * 2 {
            // Gravity settled = sparse
            verticalScore = 2
        } else if middleThird > topThird && middleThird > bottomThird {
            // Balanced
            verticalScore = 6.5
        } else {
            verticalScore = 5
        }
        
        // Line detection heuristic
        let avgDetectionY = (topThird > 0 || middleThird > 0 || bottomThird > 0) ?
            (topThird * 0.17 + middleThird * 0.5 + bottomThird * 0.83) / (topThird + middleThird + bottomThird) : 0.5
        
        let fillLineScore = min(10, ((1 - avgDetectionY) * 10))
        
        // Scoring components
        let fillScore = min(10, (fillPercent / 100) * 10)
        let vertWeighted = (verticalScore / 10) * 10
        let lineWeighted = (fillLineScore / 10) * 10
        let snackBonus = min(1.8, snackPercent / 15) * 10
        let detectionBonusScore = (detectionBonus / 10) * 10
        
        // IMPROVED FORMULA: Prioritize vertical distribution
        let combinedScore = (
            vertWeighted * 0.35 +    // 35% - CRITICAL: items at top = full
            fillScore * 0.30 +       // 30% - area coverage
            snackBonus * 0.20 +      // 20% - snack/galleta detection
            lineWeighted * 0.10 +    // 10% - line position
            detectionBonusScore * 0.05 // 5% - bonus for multiple items
        )
        
        let finalScore = min(10, max(0, combinedScore))
        
        // Categorize
        let category = categorizeScore(finalScore)
        
        return VisualOccupancyResult(
            finalScore: round(finalScore * 100) / 100,
            category: category,
            fillPercent: round(fillPercent * 100) / 100,
            snackPercent: round(snackPercent * 100) / 100,
            verticalScore: round(verticalScore * 100) / 100,
            fillLineScore: round(fillLineScore * 100) / 100,
            detectionCount: detections.count,
            topRatio: round(topRatio * 100) / 100,
            detail: "\(detections.count) items detected, \(Int(snackPercent))% appear to be snacks/galletas. Items packed at top: \(Int(topRatio * 100))%"
        )
    }
    
    /// Categorize occupancy score
    private func categorizeScore(_ score: Float) -> OccupancyCategory {
        if score < 1 {
            return .empty
        } else if score < 3 {
            return .sparse
        } else if score < 5 {
            return .partial
        } else if score < 7 {
            return .good
        } else if score < 9 {
            return .nearlyFull
        } else {
            return .full
        }
    }
    
    // MARK: - Smart Cookie Detection
    
    /// Detect cookies using fill line analysis
    func detectCookiesByFillLines(
        detections: [Detection],
        frameWidth: Float,
        frameHeight: Float
    ) -> [Detection] {
        
        let drawers = detectDrawerRegions(frameWidth: frameWidth, frameHeight: frameHeight)
        var cookieDetections: [Detection] = []
        
        for drawer in drawers {
            let bottlesInDrawer = detectBottlesInDrawer(detections: detections, drawerBbox: drawer.bbox)
            
            // If no bottles but drawer appears to have content, it's cookies
            if bottlesInDrawer.isEmpty {
                _ = calculateFillPercentage(drawerBbox: drawer.bbox, imageHeight: frameHeight)

                let cookieDetection = Detection(
                    className: "cookie",
                    confidence: 0.8,
                    boundingBox: Detection.BoundingBox(
                        x: drawer.bbox.x,
                        y: drawer.bbox.y,
                        width: drawer.bbox.width,
                        height: drawer.bbox.height
                    ),
                    frame: Detection.FrameInfo(width: frameWidth, height: frameHeight)
                )
                
                cookieDetections.append(cookieDetection)
            }
        }
        
        return cookieDetections
    }
    
    /// Detect drawer regions in the image
    private func detectDrawerRegions(frameWidth: Float, frameHeight: Float) -> [DrawerRegion] {
        var drawers: [DrawerRegion] = []
        let drawerHeight = frameHeight / 4 // Each drawer is about 1/4 of image height
        
        for i in 0..<3 { // 3 main drawers
            let yStart = frameHeight * 0.2 + Float(i) * drawerHeight
            _ = yStart + drawerHeight // yEnd calculated but not used

            // Left side drawer
            drawers.append(DrawerRegion(
                id: "drawer_\(i)_left",
                bbox: DrawerBbox(x: 0, y: yStart, width: frameWidth/2, height: drawerHeight),
                side: "left"
            ))
            
            // Right side drawer
            drawers.append(DrawerRegion(
                id: "drawer_\(i)_right",
                bbox: DrawerBbox(x: frameWidth/2, y: yStart, width: frameWidth/2, height: drawerHeight),
                side: "right"
            ))
        }
        
        return drawers
    }
    
    /// Check if there are bottles in a specific drawer
    private func detectBottlesInDrawer(detections: [Detection], drawerBbox: DrawerBbox) -> [Detection] {
        let beverageKeywords = ["bottle", "can", "coke", "soda", "water", "juice", "drink", "lata", "carton", "cup"]
        
        return detections.filter { detection in
            let label = detection.className.lowercased()
            guard beverageKeywords.contains(where: { label.contains($0) }) else { return false }
            
            let detX1 = detection.boundingBox.x
            let detY1 = detection.boundingBox.y
            let detX2 = detX1 + detection.boundingBox.width
            let detY2 = detY1 + detection.boundingBox.height
            
            let drawerX1 = drawerBbox.x
            let drawerY1 = drawerBbox.y
            let drawerX2 = drawerX1 + drawerBbox.width
            let drawerY2 = drawerY1 + drawerBbox.height
            
            // Check if detection overlaps with drawer
            return detX1 < drawerX2 && detX2 > drawerX1 && detY1 < drawerY2 && detY2 > drawerY1
        }
    }
    
    /// Calculate fill percentage based on drawer position
    private func calculateFillPercentage(drawerBbox: DrawerBbox, imageHeight: Float) -> Float {
        let drawerY1 = drawerBbox.y
        
        if drawerY1 < imageHeight * 0.3 {
            return 100
        } else if drawerY1 < imageHeight * 0.6 {
            return 75
        } else {
            return 50
        }
    }
    
    // MARK: - Supporting Structures
    
    private struct DrawerRegion {
        let id: String
        let bbox: DrawerBbox
        let side: String
    }
    
    private struct DrawerBbox {
        let x: Float
        let y: Float
        let width: Float
        let height: Float
    }
}

// MARK: - Model Configuration

/// Model configuration for trolley occupancy detection
struct TrolleyModelConfig {
    let confidence: Float
    let iou: Float
    let imageSize: Int
    let specName: String
    
    static let `default` = TrolleyModelConfig(
        confidence: 0.15,
        iou: 0.6,
        imageSize: 960,
        specName: "default.mx"
    )
}

// MARK: - Usage Example

/*
 Example usage:
 
 let model = TrolleyOccupancyModel()
 let config = TrolleyModelConfig.default
 
 // Process detections
 let normalizedDetections = model.normalizeDetections(rawDetections)
 
 // Analyze visual occupancy
 let occupancyResult = model.estimateVisualOccupancyHeuristic(
     detections: normalizedDetections,
     frameWidth: 640,
     frameHeight: 480
 )
 
 // Detect cookies using fill lines
 let cookieDetections = model.detectCookiesByFillLines(
     detections: normalizedDetections,
     frameWidth: 640,
     frameHeight: 480
 )
 
 print("Occupancy: \(occupancyResult.category.rawValue) (\(occupancyResult.finalScore)/10)")
 print("Fill: \(occupancyResult.fillPercent)%")
 print("Cookies detected: \(cookieDetections.count)")
 */
