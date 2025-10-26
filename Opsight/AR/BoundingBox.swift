//
//  BoundingBox.swift
//  Opsight
//

import Foundation
import CoreGraphics
import simd

/// Represents a 3D bounding box for the physical cart
struct CartBoundingBox {
    let minX: Float
    let maxX: Float
    let minY: Float
    let maxY: Float
    let minZ: Float
    let maxZ: Float

    /// Cart dimensions from image (standard airline trolley)
    static let standardCart = CartBoundingBox(
        minX: -0.20, maxX: 0.20,  // 40cm wide
        minY: 0, maxY: 0.90,      // 90cm tall
        minZ: -0.30, maxZ: 0.30   // 60cm deep
    )

    /// Check if a point is inside the bounding box
    func contains(point: SIMD3<Float>) -> Bool {
        return point.x >= minX && point.x <= maxX &&
               point.y >= minY && point.y <= maxY &&
               point.z >= minZ && point.z <= maxZ
    }

    /// Get which compartment a point is in
    func getCompartment(for point: SIMD3<Float>) -> CompartmentPosition? {
        guard contains(point: point) else { return nil }

        // Determine row based on height (Y axis)
        let normalizedY = (point.y - minY) / (maxY - minY)
        let row: CompartmentRow
        if normalizedY > 0.66 {
            row = .top      // Top third
        } else if normalizedY > 0.33 {
            row = .middle   // Middle third
        } else {
            row = .bottom   // Bottom third
        }

        // Determine column based on width (X axis)
        let normalizedX = (point.x - minX) / (maxX - minX)
        let column: CompartmentColumn
        if normalizedX < 0.4 {
            column = .left
        } else if normalizedX > 0.6 {
            column = .right
        } else {
            column = .center
        }

        return CompartmentPosition(row: row, column: column)
    }

    /// Calculate accuracy: percentage of item within correct compartment
    func calculatePlacementAccuracy(
        itemBox: CGRect,
        expectedCompartment: CompartmentPosition
    ) -> Double {
        // Convert 2D bounding box to 3D approximation
        // This is simplified - real implementation would use depth data
        let centerX = Float(itemBox.midX - 0.5) * (maxX - minX) * 2
        let centerY = Float(1.0 - itemBox.midY) * (maxY - minY) // Invert Y
        let centerZ: Float = 0 // Assume center depth

        let itemCenter = SIMD3<Float>(centerX, centerY, centerZ)

        // Get actual compartment
        guard let actualCompartment = getCompartment(for: itemCenter) else {
            return 0.0 // Outside cart
        }

        // Check if correct compartment
        if actualCompartment == expectedCompartment {
            // Calculate how centered the item is within the compartment
            let compartmentBounds = getCompartmentBounds(expectedCompartment)
            let centeredness = calculateCenteredness(itemCenter, in: compartmentBounds)
            return max(0.8, centeredness) // At least 80% if in right compartment
        } else if actualCompartment.row == expectedCompartment.row {
            return 0.5 // Same row, wrong column
        } else {
            return 0.2 // Wrong row
        }
    }

    /// Get bounds for a specific compartment
    func getCompartmentBounds(_ compartment: CompartmentPosition) -> CartBoundingBox {
        let rowHeight = (maxY - minY) / 3.0

        let rowMinY: Float
        let rowMaxY: Float
        switch compartment.row {
        case .bottom:
            rowMinY = minY
            rowMaxY = minY + rowHeight
        case .middle:
            rowMinY = minY + rowHeight
            rowMaxY = minY + rowHeight * 2
        case .top:
            rowMinY = minY + rowHeight * 2
            rowMaxY = maxY
        }

        let columnWidth = (maxX - minX) / 3.0

        let colMinX: Float
        let colMaxX: Float
        switch compartment.column {
        case .left:
            colMinX = minX
            colMaxX = minX + columnWidth
        case .center:
            colMinX = minX + columnWidth
            colMaxX = minX + columnWidth * 2
        case .right:
            colMinX = minX + columnWidth * 2
            colMaxX = maxX
        }

        return CartBoundingBox(
            minX: colMinX, maxX: colMaxX,
            minY: rowMinY, maxY: rowMaxY,
            minZ: minZ, maxZ: maxZ
        )
    }

    /// Calculate how centered an item is within a compartment (0.0 to 1.0)
    private func calculateCenteredness(_ point: SIMD3<Float>, in bounds: CartBoundingBox) -> Double {
        let compartmentCenter = SIMD3<Float>(
            (bounds.minX + bounds.maxX) / 2,
            (bounds.minY + bounds.maxY) / 2,
            (bounds.minZ + bounds.maxZ) / 2
        )

        let distance = simd_distance(point, compartmentCenter)
        let maxDistance = simd_length(SIMD3<Float>(
            (bounds.maxX - bounds.minX) / 2,
            (bounds.maxY - bounds.minY) / 2,
            (bounds.maxZ - bounds.minZ) / 2
        ))

        let centeredness = max(0.0, 1.0 - Double(distance / maxDistance))
        return centeredness
    }

    /// Visual debug representation
    func debugDescription() -> String {
        return """
        CartBoundingBox:
          X: [\(minX), \(maxX)]
          Y: [\(minY), \(maxY)]
          Z: [\(minZ), \(maxZ)]
        """
    }
}

/// Extension for compartment visualization
extension CompartmentPosition {
    /// Get the expected bounds for this compartment in normalized coordinates (0-1)
    var normalizedBounds: CGRect {
        let rowHeight: CGFloat = 1.0 / 3.0
        let colWidth: CGFloat = 1.0 / 3.0

        let y: CGFloat
        switch row {
        case .bottom:
            y = rowHeight * 2 // Bottom in vision coordinates (inverted Y)
        case .middle:
            y = rowHeight
        case .top:
            y = 0
        }

        let x: CGFloat
        switch column {
        case .left:
            x = 0
        case .center:
            x = colWidth
        case .right:
            x = colWidth * 2
        }

        return CGRect(x: x, y: y, width: colWidth, height: rowHeight)
    }

    /// Display name for accessibility
    var displayName: String {
        let rowName: String
        switch row {
        case .top: rowName = "Top"
        case .middle: rowName = "Middle"
        case .bottom: rowName = "Bottom"
        }

        let colName: String
        switch column {
        case .left: colName = "Left"
        case .center: colName = "Center"
        case .right: colName = "Right"
        }

        return "\(rowName) \(colName)"
    }
}
