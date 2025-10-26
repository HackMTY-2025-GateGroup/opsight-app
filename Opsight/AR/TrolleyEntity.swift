//
//  TrolleyEntity.swift
//  Opsight
//
//  Created by toño on 25/10/25.
//

import RealityKit
import ARKit
import SwiftUI

/// 3D model of airline trolley cart with compartments
/// Creates visual overlays matching physical cart structure
class TrolleyEntity: Entity {

    // MARK: - Cart Dimensions (in meters, based on real airline trolley from image)

    static let cartWidth: Float = 0.38   // 38cm wide (single unit)
    static let cartHeight: Float = 1.00  // 100cm tall
    static let cartDepth: Float = 0.56   // 56cm deep

    static let compartmentHeight: Float = 0.16 // Each drawer ~16cm (6 drawers)
    static let compartmentSpacing: Float = 0.02 // 2cm between drawers

    // MARK: - Factory Methods

    /// Creates a transparent gray guide trolley for alignment
    /// This is the AR overlay that users align their physical cart with
    /// OPTIMIZED: Minimal entities for better performance
    static func createGuideCart(manifest: CartManifest) -> Entity {
        let cartEntity = Entity()

        // Create single transparent gray frame outline (no separate markers)
        let frameEntity = createTransparentGuideFrame()
        cartEntity.addChild(frameEntity)

        // Only add 4 corner markers at the base for alignment (not all 8)
        let markers = createBaseCornerMarkers()
        for marker in markers {
            cartEntity.addChild(marker)
        }

        return cartEntity
    }

    /// Creates a complete trolley cart with compartments matching the manifest
    /// OPTIMIZED: Minimal entities for performance
    static func createCart(manifest: CartManifest) -> Entity {
        let cartEntity = Entity()

        // Add cart frame outline only
        let frameEntity = createCartFrame()
        cartEntity.addChild(frameEntity)

        // REMOVED: Complex compartments and labels for performance
        // In production, would add these back with LOD (Level of Detail) system

        return cartEntity
    }

    // MARK: - Cart Frame

    /// Creates transparent guide frame for alignment (ENHANCED VISIBILITY)
    private static func createTransparentGuideFrame() -> ModelEntity {
        // Create wireframe box outline for better visibility
        let mesh = MeshResource.generateBox(
            width: cartWidth,
            height: cartHeight,
            depth: cartDepth
        )

        var material = SimpleMaterial()
        // Bright cyan with medium opacity - optimized for AR visibility
        material.color = .init(tint: UIColor.systemCyan.withAlphaComponent(0.7))
        material.roughness = MaterialScalarParameter(floatLiteral: 1.0)
        material.metallic = MaterialScalarParameter(floatLiteral: 0.0)

        let model = ModelEntity(mesh: mesh, materials: [material])
        model.position = SIMD3<Float>(0, cartHeight / 2, 0)
        model.name = "guideFrame"

        return model
    }

    /// Creates 4 bright corner markers at the base (enhanced visibility)
    private static func createBaseCornerMarkers() -> [Entity] {
        var markers: [Entity] = []
        let markerSize: Float = 0.05 // Slightly larger for visibility
        let halfWidth = cartWidth / 2
        let halfDepth = cartDepth / 2

        // Only bottom 4 corners for alignment
        let corners: [(x: Float, y: Float, z: Float)] = [
            (halfWidth, 0, halfDepth),
            (halfWidth, 0, -halfDepth),
            (-halfWidth, 0, halfDepth),
            (-halfWidth, 0, -halfDepth)
        ]

        for (index, corner) in corners.enumerated() {
            let mesh = MeshResource.generateSphere(radius: markerSize)

            var material = SimpleMaterial()
            // Bright yellow for high visibility
            material.color = .init(tint: UIColor.systemYellow.withAlphaComponent(0.9))

            let marker = ModelEntity(mesh: mesh, materials: [material])
            marker.position = SIMD3<Float>(corner.x, corner.y, corner.z)
            marker.name = "cornerMarker\(index)"

            markers.append(marker)
        }

        return markers
    }

    // REMOVED: createGuideLines() for performance - simplified visual

    private static func createCartFrame() -> ModelEntity {
        // Create transparent box outlining the cart
        let mesh = MeshResource.generateBox(
            width: cartWidth,
            height: cartHeight,
            depth: cartDepth
        )

        var material = SimpleMaterial()
        material.color = .init(tint: .blue.withAlphaComponent(0.2))
        material.roughness = MaterialScalarParameter(floatLiteral: 0.8)

        let model = ModelEntity(mesh: mesh, materials: [material])
        model.position = SIMD3<Float>(0, cartHeight / 2, 0)

        return model
    }

    // MARK: - Compartments

    private static func createCompartments(for manifest: CartManifest) -> [Entity] {
        var compartments: [Entity] = []

        // Group items by category
        let categorizedItems = Dictionary(grouping: manifest.expectedItems) { $0.category }

        // Create compartments (top, middle, bottom)
        let positions: [(row: CompartmentRow, yOffset: Float)] = [
            (.top, cartHeight - compartmentHeight / 2 - 0.1),
            (.middle, cartHeight / 2),
            (.bottom, compartmentHeight / 2 + 0.1)
        ]

        for (index, position) in positions.enumerated() {
            let compartment = createCompartment(
                at: position.yOffset,
                row: position.row,
                items: categorizedItems[getCategory(for: index)] ?? []
            )
            compartments.append(compartment)
        }

        return compartments
    }

    private static func createCompartment(
        at yPosition: Float,
        row: CompartmentRow,
        items: [MealItem]
    ) -> Entity {
        let compartmentEntity = Entity()

        // Create drawer outline
        let mesh = MeshResource.generateBox(
            width: cartWidth - 0.02,
            height: compartmentHeight,
            depth: cartDepth - 0.02
        )

        var material = SimpleMaterial()
        material.color = .init(tint: getCompartmentColor(for: row).withAlphaComponent(0.3))
        material.roughness = MaterialScalarParameter(floatLiteral: 0.9)

        let model = ModelEntity(mesh: mesh, materials: [material])
        model.position = SIMD3<Float>(0, yPosition, 0)

        compartmentEntity.addChild(model)

        // Add item slots
        let slots = createItemSlots(items: items, yPosition: yPosition)
        for slot in slots {
            compartmentEntity.addChild(slot)
        }

        return compartmentEntity
    }

    private static func createItemSlots(items: [MealItem], yPosition: Float) -> [Entity] {
        var slots: [Entity] = []

        let slotSize: Float = 0.08 // 8cm slots
        let slotsPerRow = Int(cartWidth / slotSize)

        for (index, item) in items.enumerated() {
            let row = Float(index / slotsPerRow)
            let col = Float(index % slotsPerRow)

            let xOffset = (col - Float(slotsPerRow) / 2) * slotSize
            let zOffset = (row - 1) * slotSize

            let slot = createItemSlot(
                at: SIMD3<Float>(xOffset, yPosition, zOffset),
                for: item
            )
            slots.append(slot)
        }

        return slots
    }

    private static func createItemSlot(at position: SIMD3<Float>, for item: MealItem) -> Entity {
        let slotEntity = Entity()

        // Create small cube representing expected item
        let size: Float = 0.06
        let mesh = MeshResource.generateBox(size: size)

        var material = SimpleMaterial()
        material.color = .init(tint: getCategoryColor(item.category).withAlphaComponent(0.5), texture: nil)

        let model = ModelEntity(mesh: mesh, materials: [material])
        model.position = position

        slotEntity.addChild(model)

        return slotEntity
    }

    // MARK: - Labels

    private static func createCompartmentLabels(for manifest: CartManifest) -> [Entity] {
        var labels: [Entity] = []

        let labelPositions: [(String, Float)] = [
            ("MEALS", cartHeight - 0.1),
            ("SNACKS", cartHeight / 2),
            ("BEVERAGES", 0.2)
        ]

        for (text, yPos) in labelPositions {
            if let label = createTextLabel(text: text, at: SIMD3<Float>(-cartWidth / 2 - 0.1, yPos, 0)) {
                labels.append(label)
            }
        }

        return labels
    }

    private static func createTextLabel(text: String, at position: SIMD3<Float>) -> Entity? {
        let labelEntity = Entity()

        // Create text mesh
        let mesh = MeshResource.generateText(
            text,
            extrusionDepth: 0.01,
            font: .systemFont(ofSize: 0.05),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byTruncatingTail
        )

        var material = SimpleMaterial()
        material.color = .init(tint: .white)

        let model = ModelEntity(mesh: mesh, materials: [material])
        model.position = position

        // Rotate to face user
        model.orientation = simd_quatf(angle: .pi / 2, axis: SIMD3<Float>(0, 1, 0))

        labelEntity.addChild(model)

        return labelEntity
    }

    // MARK: - Helper Methods

    private static func getCategory(for index: Int) -> MealItem.ItemCategory {
        switch index {
        case 0: return .lunch  // Top compartment
        case 1: return .snack  // Middle compartment
        case 2: return .beverage // Bottom compartment
        default: return .snack
        }
    }

    private static func getCompartmentColor(for row: CompartmentRow) -> UIColor {
        switch row {
        case .top: return .systemBlue
        case .middle: return .systemOrange
        case .bottom: return .systemCyan
        }
    }

    private static func getCategoryColor(_ category: MealItem.ItemCategory) -> UIColor {
        // Convert SwiftUI Color to UIColor
        return UIColor(category.color)
    }

    // MARK: - Visual Feedback

    /// Highlights a compartment when an item is detected
    static func highlightCompartment(_ compartment: CompartmentPosition, in entity: Entity, color: UIColor) {
        // Find compartment entity and pulse it
        // Implementation would traverse entity hierarchy and apply animation
    }

    /// Shows checkmark or X mark on compartment
    static func showValidationIndicator(
        _ status: DetectedItemResult.ValidationStatus,
        at compartment: CompartmentPosition,
        in entity: Entity
    ) {
        // Create checkmark or X mark entity
        let indicator = createValidationIcon(status)
        entity.addChild(indicator)

        // Animate indicator
        animateIndicator(indicator)
    }

    /// Creates a detection indicator for a detected item
    /// Visualizes bounding boxes and confidence in AR space
    static func createDetectionIndicator(
        for detection: Detection,
        occupancyCategory: OccupancyCategory
    ) -> Entity {
        let indicatorEntity = Entity()

        // Calculate normalized position in cart space
        let normalizedY = detection.boundingBox.y / detection.frame.height
        let normalizedX = detection.boundingBox.x / detection.frame.width

        // Map to cart dimensions
        let xPos = (normalizedX - 0.5) * cartWidth
        let yPos = normalizedY * cartHeight
        let zPos: Float = cartDepth / 2 + 0.05 // Slightly in front of cart

        // Create indicator sphere
        let radius: Float = 0.03
        let mesh = MeshResource.generateSphere(radius: radius)

        var material = SimpleMaterial()
        let indicatorColor = getIndicatorColor(for: occupancyCategory)
        material.color = .init(tint: indicatorColor)

        let model = ModelEntity(mesh: mesh, materials: [material])
        model.position = SIMD3<Float>(xPos, yPos, zPos)

        indicatorEntity.addChild(model)

        // Add pulsing animation
        animateDetectionIndicator(model)

        return indicatorEntity
    }

    /// Animates a detection indicator with pulsing effect
    private static func animateDetectionIndicator(_ indicator: ModelEntity) {
        var smallTransform = indicator.transform
        smallTransform.scale = SIMD3<Float>(0.8, 0.8, 0.8)

        var largeTransform = indicator.transform
        largeTransform.scale = SIMD3<Float>(1.2, 1.2, 1.2)

        // Pulse animation
        indicator.move(
            to: largeTransform,
            relativeTo: indicator.parent,
            duration: 0.6,
            timingFunction: .easeInOut
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            indicator.move(
                to: smallTransform,
                relativeTo: indicator.parent,
                duration: 0.6,
                timingFunction: .easeInOut
            )
        }
    }

    /// Gets color for occupancy category
    private static func getIndicatorColor(for category: OccupancyCategory) -> UIColor {
        switch category {
        case .empty: return .gray
        case .sparse: return .systemRed
        case .partial: return .systemOrange
        case .good: return .systemYellow
        case .nearlyFull: return .systemGreen
        case .full: return .systemCyan
        }
    }

    /// Updates the guide trolley color based on alignment status
    /// - Parameters:
    ///   - entity: The guide cart entity (parent containing frame and markers)
    ///   - isAligned: Whether the physical cart is properly aligned
    ///   - brightness: Opacity level (0.0 to 1.0) for visibility
    static func updateGuideColor(entity: Entity, isAligned: Bool, brightness: CGFloat = 0.6) {
        // Find frame entity by name
        var frameEntity: ModelEntity?
        for child in entity.children {
            if let modelEntity = child as? ModelEntity, modelEntity.name == "guideFrame" {
                frameEntity = modelEntity
                break
            }
        }
        
        guard let frame = frameEntity else {
            // Fallback: try first child
            guard let frame = entity.children.first as? ModelEntity else { return }
            updateFrameMaterial(frame, isAligned: isAligned, brightness: brightness)
            updateMarkerMaterials(entity, isAligned: isAligned, brightness: brightness)
            return
        }

        updateFrameMaterial(frame, isAligned: isAligned, brightness: brightness)
        updateMarkerMaterials(entity, isAligned: isAligned, brightness: brightness)
    }
    
    private static func updateFrameMaterial(_ frameEntity: ModelEntity, isAligned: Bool, brightness: CGFloat) {
        var material = SimpleMaterial()
        if isAligned {
            // Bright green when aligned/ready
            material.color = .init(tint: UIColor.systemGreen.withAlphaComponent(brightness))
        } else {
            // Bright cyan when manipulating
            material.color = .init(tint: UIColor.systemCyan.withAlphaComponent(brightness))
        }
        material.roughness = MaterialScalarParameter(floatLiteral: 1.0)
        material.metallic = MaterialScalarParameter(floatLiteral: 0.0)

        frameEntity.model?.materials = [material]
    }
    
    private static func updateMarkerMaterials(_ entity: Entity, isAligned: Bool, brightness: CGFloat) {
        // Update corner markers
        for child in entity.children where child is ModelEntity && child.name.starts(with: "cornerMarker") == true {
            guard let markerEntity = child as? ModelEntity else { continue }

            var markerMaterial = SimpleMaterial()
            if isAligned {
                // Green markers when ready
                markerMaterial.color = .init(tint: UIColor.systemGreen.withAlphaComponent(0.9))
            } else {
                // Yellow markers when manipulating
                markerMaterial.color = .init(tint: UIColor.systemYellow.withAlphaComponent(0.9))
            }

            markerEntity.model?.materials = [markerMaterial]
        }
    }

    private static func createValidationIcon(_ status: DetectedItemResult.ValidationStatus) -> Entity {
        let iconEntity = Entity()

        let size: Float = 0.1
        let mesh = MeshResource.generatePlane(width: size, height: size)

        var material = SimpleMaterial()
        // Convert SwiftUI Color to UIColor
        material.color = .init(tint: UIColor(status.color))

        let model = ModelEntity(mesh: mesh, materials: [material])
        iconEntity.addChild(model)

        return iconEntity
    }

    private static func animateIndicator(_ indicator: Entity) {
        // Scale animation
        var transform = indicator.transform
        transform.scale = SIMD3<Float>(0.1, 0.1, 0.1)

        indicator.move(
            to: transform,
            relativeTo: indicator.parent,
            duration: 0.3,
            timingFunction: .easeOut
        )

        // Fade out after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            indicator.removeFromParent()
        }
    }
}

// MARK: - Extensions

extension MealItem.ItemCategory {
    /// Icon for AR visualization
    var arIcon: String {
        switch self {
        case .breakfast: return "☀️"
        case .lunch: return "🍱"
        case .dinner: return "🍽️"
        case .snack: return "🍿"
        case .beverage: return "🥤"
        case .specialty: return "⭐"
        }
    }
}
