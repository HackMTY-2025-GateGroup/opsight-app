//
//  PlaneVisualization.swift
//  Opsight
//
//  Created by toño on 25/10/25.
//

import RealityKit
import ARKit

/// Helper to visualize detected AR planes
class PlaneVisualization {

    /// Creates a semi-transparent mesh to visualize a detected plane (ENHANCED VISIBILITY)
    static func createPlaneEntity(for anchor: ARPlaneAnchor) -> ModelEntity {
        let extent = anchor.planeSize

        // Limit plane visualization size to avoid large meshes
        let maxSize: Float = 2.0
        let width = min(extent.width, maxSize)
        let height = min(extent.height, maxSize)

        // Create simple plane mesh - RealityKit generates planes in XZ by default (horizontal)
        let mesh = MeshResource.generatePlane(
            width: width,
            depth: height
        )

        // Create highly visible material with semi-transparency
        var material = SimpleMaterial()
        // Semi-transparent cyan for floor visualization
        material.color = .init(
            tint: UIColor.systemCyan.withAlphaComponent(0.3),
            texture: nil
        )
        material.roughness = MaterialScalarParameter(floatLiteral: 1.0)
        material.metallic = MaterialScalarParameter(floatLiteral: 0.0)

        let planeEntity = ModelEntity(mesh: mesh, materials: [material])
        planeEntity.name = "detectedPlane"

        // Position the plane entity at the center of the detected plane
        // RealityKit planes are already horizontal (XZ plane), no rotation needed
        planeEntity.transform.translation = SIMD3<Float>(
            anchor.center.x,
            0, // Keep at plane's Y level
            anchor.center.z
        )

        // Add subtle pulsing animation for better visibility
        addPulseAnimation(to: planeEntity)

        return planeEntity
    }
    
    /// Adds a subtle pulsing animation to make planes more noticeable
    private static func addPulseAnimation(to entity: ModelEntity) {
        // Create a subtle scale pulse
        var smallTransform = entity.transform
        smallTransform.scale = SIMD3<Float>(0.95, 0.95, 0.95)
        
        var largeTransform = entity.transform
        largeTransform.scale = SIMD3<Float>(1.0, 1.0, 1.0)
        
        // Animate between the two states
        entity.move(
            to: largeTransform,
            relativeTo: entity.parent,
            duration: 0.8,
            timingFunction: .easeInOut
        )
        
        // Set up repeating animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            entity.move(
                to: smallTransform,
                relativeTo: entity.parent,
                duration: 0.8,
                timingFunction: .easeInOut
            )
        }
    }

    /// Updates an existing plane entity to match the anchor's new extent (ENHANCED)
    static func updatePlaneEntity(_ entity: ModelEntity, for anchor: ARPlaneAnchor) {
        let extent = anchor.planeSize

        // Limit plane visualization size
        let maxSize: Float = 2.0
        let width = min(extent.width, maxSize)
        let height = min(extent.height, maxSize)

        // Update mesh size
        let mesh = MeshResource.generatePlane(
            width: width,
            depth: height
        )

        entity.model?.mesh = mesh

        // Update position smoothly (keep on floor)
        entity.transform.translation = SIMD3<Float>(
            anchor.center.x,
            0, // Keep at plane's Y level
            anchor.center.z
        )

        // Update material to ensure visibility remains consistent
        var material = SimpleMaterial()
        material.color = .init(
            tint: UIColor.systemCyan.withAlphaComponent(0.3),
            texture: nil
        )
        material.roughness = MaterialScalarParameter(floatLiteral: 1.0)
        material.metallic = MaterialScalarParameter(floatLiteral: 0.0)

        entity.model?.materials = [material]
    }

    // REMOVED: createGridEntity() - too many entities, causing performance issues
    // Grid visualization disabled for better performance on all devices
}

// MARK: - Extensions

extension ARPlaneAnchor {
    /// Returns the plane extent (width and height)
    var planeSize: PlaneExtent {
        // ARPlaneGeometry has vertices that we can use to calculate bounds
        // But the simplest approach is to use a default size or calculate from vertices
        // For now, use a reasonable default size for visualization
        let vertices = geometry.vertices
        guard vertices.count > 0 else {
            return PlaneExtent(width: 1.0, height: 1.0)
        }

        var minX: Float = .infinity
        var maxX: Float = -.infinity
        var minZ: Float = .infinity
        var maxZ: Float = -.infinity

        for vertex in vertices {
            minX = min(minX, vertex.x)
            maxX = max(maxX, vertex.x)
            minZ = min(minZ, vertex.z)
            maxZ = max(maxZ, vertex.z)
        }

        let width = maxX - minX
        let height = maxZ - minZ

        return PlaneExtent(
            width: width,
            height: height
        )
    }
}

struct PlaneExtent {
    let width: Float
    let height: Float
}
