//
//  ARTrolleyViewModel.swift
//  Opsight
//
//  Created by toño on 25/10/25.
//

import Foundation
import ARKit
import RealityKit
import Combine
import Vision
import SwiftUI

// Type alias for compatibility
typealias MealCategory = MealItem.ItemCategory

/// State for AR session
enum ARSessionState {
    case initializing
    case searchingForSurface
    case surfaceDetected
    case cartPlaced
    case scanning
    case paused
    case completed

    var icon: String {
        switch self {
        case .initializing: return "arrow.clockwise"
        case .searchingForSurface: return "viewfinder"
        case .surfaceDetected: return "hand.tap.fill"
        case .cartPlaced: return "checkmark.circle.fill"
        case .scanning: return "camera.viewfinder"
        case .paused: return "pause.circle"
        case .completed: return "checkmark.seal.fill"
        }
    }

    var color: Color {
        switch self {
        case .initializing: return .yellow
        case .searchingForSurface: return .orange
        case .surfaceDetected: return .cyan
        case .cartPlaced: return .green
        case .scanning: return .blue
        case .paused: return .gray
        case .completed: return .green
        }
    }

    var message: String {
        switch self {
        case .initializing: return "Starting AR..."
        case .searchingForSurface: return "Move device to find surface"
        case .surfaceDetected: return "Tap to place trolley"
        case .cartPlaced: return "Trolley placed!"
        case .scanning: return "Scanning items..."
        case .paused: return "Paused"
        case .completed: return "Scan complete!"
        }
    }
}

/// Detected item with validation result
struct DetectedItemResult: Identifiable {
    let id = UUID()
    let productName: String
    let category: MealCategory
    let boundingBox: CGRect
    let confidence: Double
    let expirationDate: Date?
    let batchNumber: String?
    let compartmentPosition: CompartmentPosition?
    let validationStatus: ValidationStatus

    enum ValidationStatus {
        case correct
        case wrongCompartment
        case wrongBatch
        case expired
        case notExpected

        var color: Color {
            switch self {
            case .correct: return .green
            case .wrongCompartment: return .orange
            case .wrongBatch: return .orange
            case .expired: return .red
            case .notExpected: return .red
            }
        }

        var icon: String {
            switch self {
            case .correct: return "checkmark.circle.fill"
            case .wrongCompartment: return "arrow.left.and.right.circle"
            case .wrongBatch: return "exclamationmark.triangle.fill"
            case .expired: return "calendar.badge.exclamationmark"
            case .notExpected: return "xmark.circle.fill"
            }
        }

        var message: String {
            switch self {
            case .correct: return "Correct position"
            case .wrongCompartment: return "Wrong compartment"
            case .wrongBatch: return "Wrong batch - use FEFO"
            case .expired: return "Expired - do not use"
            case .notExpected: return "Not in manifest"
            }
        }
    }
}

/// ViewModel managing AR session and item detection
class ARTrolleyViewModel: NSObject, ObservableObject {
    // MARK: - Published Properties

    @Published var sessionState: ARSessionState = .initializing
    @Published var manifest: CartManifest
    @Published var detectedItems: [DetectedItemResult] = []
    @Published var currentDetection: DetectedItemResult?
    @Published var showManualEntry = false
    @Published var canComplete = false
    @Published var detectedPlanes: [UUID: ARPlaneAnchor] = [:]

    // MARK: - AR Properties

    var arView: ARView?
    private var trolleyAnchor: AnchorEntity?
    private var cartEntity: Entity?
    private var lastPlacementTransform: simd_float4x4?
    private var baseRotation: Float = 0.0
    private var detectionIndicators: [Entity] = []

    // MARK: - Detection Properties

    private var frameCounter = 0
    private let frameSkipCount = 60 // Process every 60th frame (approx 1 per second) for better performance
    private var isProcessingFrame = false
    private var visionRequestHandler: VNSequenceRequestHandler?

    // MARK: - MLX Integration

    private let trolleyModel = TrolleyOccupancyModel()
    @Published var occupancyResult: VisualOccupancyResult?
    @Published var detectedBeverages: [Detection] = []

    // MARK: - Initialization

    init(manifest: CartManifest) {
        self.manifest = manifest
        super.init()
        // Pre-create vision request handler for reuse
        self.visionRequestHandler = VNSequenceRequestHandler()
    }

    // MARK: - AR Session Management

    func startARSession() {
        guard let arView = arView else {
            print("❌ ARView not available")
            return
        }
        
        // Configure and start session
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .none
        
        // Run session with options
        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        
        sessionState = .searchingForSurface
        HapticManager.shared.impact()
        announceState()
        
        print("✅ AR Session started")
    }

    func pauseARSession() {
        sessionState = .paused
        arView?.session.pause()
        print("⏸️ AR Session paused")
    }

    func resumeARSession() {
        guard let arView = arView else { return }
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .none
        arView.session.run(config, options: [])
        sessionState = .scanning
        print("▶️ AR Session resumed")
    }
    
    func handleSessionError(_ error: Error) {
        print("❌ AR Session error: \(error.localizedDescription)")
        DispatchQueue.main.async { [weak self] in
            self?.sessionState = .paused
            HapticManager.shared.error()
        }
    }

    // MARK: - Tap to Place Cart

    func handleTap(at location: CGPoint) {
        guard sessionState == .surfaceDetected else {
            print("⚠️ Cannot place trolley - current state: \(sessionState)")
            return
        }
        guard let arView = arView else {
            print("❌ ARView not available")
            return
        }

        print("👆 Tap detected at location: \(location)")

        // Perform raycast to find intersection with detected planes
        let results = arView.raycast(
            from: location,
            allowing: .existingPlaneGeometry,
            alignment: .horizontal
        )

        if results.isEmpty {
            print("❌ No raycast hit - tap again on the detected floor surface")
            HapticManager.shared.warning()

            // Also try estimated plane if no existing plane hit
            let estimatedResults = arView.raycast(
                from: location,
                allowing: .estimatedPlane,
                alignment: .horizontal
            )

            if let firstEstimated = estimatedResults.first {
                print("✅ Using estimated plane for placement")
                placeTrolleyCart(at: firstEstimated)
            }
            return
        }

        print("✅ Raycast hit detected plane")
        placeTrolleyCart(at: results.first!)
    }
    
    // MARK: - Drag to Move Cart
    
    func handleDrag(to location: CGPoint) {
        guard let arView = arView else { return }
        guard trolleyAnchor != nil else { return }
        
        // Perform raycast to find new position
        let results = arView.raycast(
            from: location,
            allowing: .existingPlaneGeometry,
            alignment: .horizontal
        )
        
        guard let firstResult = results.first else { return }
        
        // Update trolley position smoothly
        moveTrolleyCart(to: firstResult)
    }
    
    // MARK: - Rotation Gestures

    func handleRotation(angle: Angle) {
        guard let trolleyAnchor = trolleyAnchor else { return }

        // Convert SwiftUI Angle to radians (delta rotation)
        let deltaRadians = Float(angle.radians)

        // Apply incremental rotation around Y axis (vertical)
        let currentRotation = trolleyAnchor.orientation
        let deltaRotation = simd_quatf(angle: deltaRadians, axis: SIMD3<Float>(0, 1, 0))
        trolleyAnchor.orientation = simd_mul(deltaRotation, currentRotation)

        // Update visual feedback
        updateTrolleyVisibility(isManipulating: true)
    }

    func commitRotation(angle: Angle) {
        // Commit the final rotation
        baseRotation += Float(angle.radians)

        // Normalize rotation to 0-2π
        baseRotation = baseRotation.truncatingRemainder(dividingBy: 2 * .pi)

        // Reset visual feedback
        updateTrolleyVisibility(isManipulating: false)

        HapticManager.shared.impact()
        print("🔄 Trolley rotated to: \(baseRotation) radians (\(Int(baseRotation * 180 / .pi))°)")
    }

    private func placeTrolleyCart(at raycastResult: ARRaycastResult) {
        guard let arView = arView else {
            print("❌ ARView not available for placement")
            return
        }

        print("✅ Placing guide trolley at world position")

        // Remove existing cart if any
        if let existingAnchor = trolleyAnchor {
            print("🗑️ Removing existing trolley")
            existingAnchor.removeFromParent()
        }

        // Create anchor at the raycast result's world transform
        let anchor = AnchorEntity(world: raycastResult.worldTransform)

        // **USE GUIDE CART - enhanced visibility**
        let cart = TrolleyEntity.createGuideCart(manifest: manifest)
        anchor.addChild(cart)

        print("📦 Cart entity created with \(cart.children.count) child entities")

        // Add to scene
        arView.scene.addAnchor(anchor)
        print("🌍 Anchor added to AR scene")

        // Store references
        trolleyAnchor = anchor
        cartEntity = cart
        lastPlacementTransform = raycastResult.worldTransform
        baseRotation = 0.0

        // Update state
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.sessionState = .cartPlaced
            HapticManager.shared.success()
            self.announceState()

            // Auto-start scanning after brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                guard let self = self else { return }
                self.sessionState = .scanning
                self.announceState()
                print("📸 Started scanning mode")
            }
        }
    }
    
    private func moveTrolleyCart(to raycastResult: ARRaycastResult) {
        guard let trolleyAnchor = trolleyAnchor else { return }
        
        // Smoothly move anchor to new position
        var transform = Transform()
        transform.matrix = raycastResult.worldTransform
        
        // Preserve current rotation
        let currentRotation = trolleyAnchor.orientation
        
        // Animate to new position
        trolleyAnchor.move(
            to: transform,
            relativeTo: nil,
            duration: 0.1,
            timingFunction: .easeOut
        )
        
        // Restore rotation
        trolleyAnchor.orientation = currentRotation
        
        lastPlacementTransform = raycastResult.worldTransform
    }
    
    private func updateTrolleyVisibility(isManipulating: Bool) {
        guard let cartEntity = cartEntity else { return }
        
        // Update visual feedback during manipulation
        if isManipulating {
            // Slightly brighter during manipulation
            TrolleyEntity.updateGuideColor(entity: cartEntity, isAligned: false, brightness: 0.7)
        } else {
            // Normal visibility
            TrolleyEntity.updateGuideColor(entity: cartEntity, isAligned: true, brightness: 0.6)
        }
    }

    // MARK: - Plane Detection

    func handlePlaneDetection(_ planeAnchor: ARPlaneAnchor) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Store detected plane
            self.detectedPlanes[planeAnchor.identifier] = planeAnchor

            // Update state if we found a suitable surface
            if self.sessionState == .searchingForSurface {
                // Check if plane is large enough (at least 50cm x 50cm)
                let extent = planeAnchor.planeSize
                if extent.width > 0.5 && extent.height > 0.5 {
                    self.sessionState = .surfaceDetected
                    HapticManager.shared.success()
                    self.announceState()
                }
            }
        }
    }

    func handlePlaneUpdate(_ planeAnchor: ARPlaneAnchor) {
        DispatchQueue.main.async { [weak self] in
            self?.detectedPlanes[planeAnchor.identifier] = planeAnchor
        }
    }

    func handlePlaneRemoval(_ planeAnchor: ARPlaneAnchor) {
        DispatchQueue.main.async { [weak self] in
            self?.detectedPlanes.removeValue(forKey: planeAnchor.identifier)
        }
    }

    // MARK: - Frame Processing

    func processFrame(_ frame: ARFrame) {
        frameCounter += 1

        // Skip frames for performance
        guard frameCounter % frameSkipCount == 0 else { return }
        guard !isProcessingFrame else { return }
        guard sessionState == .scanning else { return }

        isProcessingFrame = true

        // Process frame on background queue
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            // Detect items in the frame
            self.detectItems(in: frame)

            DispatchQueue.main.async {
                self.isProcessingFrame = false
            }
        }
    }

    // MARK: - Item Detection

    private func detectItems(in frame: ARFrame) {
        let pixelBuffer = frame.capturedImage

        // Get frame dimensions
        let frameWidth = Float(CVPixelBufferGetWidth(pixelBuffer))
        let frameHeight = Float(CVPixelBufferGetHeight(pixelBuffer))

        // Use Vision to detect rectangles and convert to MLX Detection format
        let request = VNDetectRectanglesRequest { [weak self] (request: VNRequest, error: Error?) in
            guard let self = self else { return }

            if let error = error {
                print("⚠️ Vision error: \(error.localizedDescription)")
                return
            }

            guard let results = request.results as? [VNRectangleObservation] else { return }

            // Convert Vision results to MLX Detection format
            let rawDetections = results
                .filter { $0.confidence > 0.5 }
                .sorted { $0.confidence > $1.confidence }
                .prefix(10) // Process up to 10 items
                .map { observation -> Detection in
                    let bbox = observation.boundingBox
                    return Detection(
                        className: "beverage", // Placeholder - would come from YOLO in production
                        confidence: observation.confidence,
                        boundingBox: Detection.BoundingBox(
                            x: Float(bbox.origin.x) * frameWidth,
                            y: Float(bbox.origin.y) * frameHeight,
                            width: Float(bbox.width) * frameWidth,
                            height: Float(bbox.height) * frameHeight
                        ),
                        frame: Detection.FrameInfo(
                            width: frameWidth,
                            height: frameHeight
                        )
                    )
                }

            // Process with TrolleyOccupancyModel
            self.processWithMLXModel(detections: Array(rawDetections), frameWidth: frameWidth, frameHeight: frameHeight, frame: frame)
        }

        request.minimumAspectRatio = 0.3
        request.maximumAspectRatio = 3.0
        request.minimumSize = 0.05 // Detect smaller items
        request.minimumConfidence = 0.5
        request.maximumObservations = 10

        // Reuse sequence request handler for better performance
        guard let handler = visionRequestHandler else { return }
        try? handler.perform([request], on: pixelBuffer, orientation: .up)
    }

    // MARK: - MLX Model Processing

    private func processWithMLXModel(detections: [Detection], frameWidth: Float, frameHeight: Float, frame: ARFrame) {
        // Normalize detections using TrolleyOccupancyModel
        let normalizedDetections = trolleyModel.normalizeDetections(detections)

        // Estimate visual occupancy
        let occupancy = trolleyModel.estimateVisualOccupancyHeuristic(
            detections: normalizedDetections,
            frameWidth: frameWidth,
            frameHeight: frameHeight
        )

        // Detect cookies using fill line analysis
        let cookieDetections = trolleyModel.detectCookiesByFillLines(
            detections: normalizedDetections,
            frameWidth: frameWidth,
            frameHeight: frameHeight
        )

        // Combine all detections
        let allDetections = normalizedDetections + cookieDetections

        // Update UI on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.occupancyResult = occupancy
            self.detectedBeverages = allDetections

            // Clear old detection indicators
            self.clearDetectionIndicators()

            // Add visual indicators for detected items in AR
            if let cartEntity = self.cartEntity {
                for detection in allDetections.prefix(5) { // Show top 5 detections
                    let indicator = TrolleyEntity.createDetectionIndicator(
                        for: detection,
                        occupancyCategory: occupancy.category
                    )
                    cartEntity.addChild(indicator)
                    self.detectionIndicators.append(indicator)
                }
            }

            // Convert to legacy format for display
            for detection in allDetections.prefix(3) {
                self.handleMLXDetection(detection, in: frame, occupancy: occupancy)
            }

            // Log results
            print("🔍 MLX Analysis:")
            print("  - Occupancy: \(occupancy.category.rawValue) (\(occupancy.finalScore)/10)")
            print("  - Fill: \(occupancy.fillPercent)%")
            print("  - Snacks: \(occupancy.snackPercent)%")
            print("  - Items detected: \(allDetections.count)")
            print("  - Detail: \(occupancy.detail)")
        }
    }

    private func clearDetectionIndicators() {
        for indicator in detectionIndicators {
            indicator.removeFromParent()
        }
        detectionIndicators.removeAll()
    }

    private func handleMLXDetection(_ detection: Detection, in frame: ARFrame, occupancy: VisualOccupancyResult) {
        // Determine compartment position
        let normalizedY = detection.boundingBox.y / detection.frame.height
        let normalizedX = detection.boundingBox.x / detection.frame.width

        let compartment = CompartmentPosition(
            row: normalizedY < 0.33 ? .top : (normalizedY < 0.66 ? .middle : .bottom),
            column: normalizedX < 0.5 ? .left : .right
        )

        // Map beverage type to meal category
        let beverageType = BeverageType(rawValue: detection.className) ?? .unknown
        let category: MealCategory = {
            switch beverageType {
            case .cookie: return .snack
            case .juiceBox: return .beverage
            case .can, .bottleWater: return .beverage
            case .unknown: return .beverage
            }
        }()

        // Validate against manifest
        let validation = validateMLXItem(
            beverageType: beverageType,
            compartment: compartment,
            expectedItems: manifest.expectedItems
        )

        // Create result with normalized bounding box (0-1 range for SwiftUI)
        let result = DetectedItemResult(
            productName: beverageType.rawValue.capitalized,
            category: category,
            boundingBox: CGRect(
                x: CGFloat(detection.boundingBox.x) / CGFloat(detection.frame.width),
                y: CGFloat(detection.boundingBox.y) / CGFloat(detection.frame.height),
                width: CGFloat(detection.boundingBox.width) / CGFloat(detection.frame.width),
                height: CGFloat(detection.boundingBox.height) / CGFloat(detection.frame.height)
            ),
            confidence: Double(detection.confidence),
            expirationDate: nil,
            batchNumber: nil,
            compartmentPosition: compartment,
            validationStatus: validation
        )

        // Check if already detected (avoid duplicates)
        if !detectedItems.contains(where: { $0.productName == result.productName && $0.compartmentPosition == result.compartmentPosition }) {
            detectedItems.append(result)
            currentDetection = result

            // Provide feedback
            provideFeedback(for: result)

            // Check completion
            checkCompletion()

            // Clear current detection after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                if self?.currentDetection?.id == result.id {
                    self?.currentDetection = nil
                }
            }
        }
    }

    private func validateMLXItem(
        beverageType: BeverageType,
        compartment: CompartmentPosition,
        expectedItems: [MealItem]
    ) -> DetectedItemResult.ValidationStatus {
        // Check if item type is expected
        let expectedCategories = expectedItems.map { $0.category }
        let itemCategory: MealCategory = beverageType == .cookie ? .snack : .beverage

        guard expectedCategories.contains(itemCategory) else {
            return .notExpected
        }

        // Validate compartment matches item type
        if !isCorrectCompartment(category: itemCategory, compartment: compartment) {
            return .wrongCompartment
        }

        return .correct
    }

    private func handleItemDetection(_ observation: VNRectangleObservation, in frame: ARFrame) {
        // Simplified: infer product type from position and size
        let boundingBox = observation.boundingBox
        let productName = inferProductFromPosition(boundingBox)

        // Determine which compartment the item is in
        let compartment = determineCompartment(for: boundingBox)

        // Validate against manifest
        let validation = validateItem(
            productName: productName,
            compartment: compartment,
            expectedItems: manifest.expectedItems
        )

        // Create result
        let result = DetectedItemResult(
            productName: productName,
            category: inferCategoryFromPosition(boundingBox),
            boundingBox: boundingBox,
            confidence: Double(observation.confidence),
            expirationDate: nil, // Will be filled by OCR in future
            batchNumber: nil,
            compartmentPosition: compartment,
            validationStatus: validation
        )

        // Check if already detected (avoid duplicates)
        if !detectedItems.contains(where: { $0.productName == result.productName }) {
            detectedItems.append(result)
            currentDetection = result

            // Provide feedback
            provideFeedback(for: result)

            // Check completion
            checkCompletion()

            // Clear current detection after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                if self?.currentDetection?.id == result.id {
                    self?.currentDetection = nil
                }
            }
        }
    }

    private func inferProductFromPosition(_ boundingBox: CGRect) -> String {
        // Simplified inference based on position
        let yPos = boundingBox.midY
        if yPos > 0.66 {
            return "Meal Box"
        } else if yPos > 0.33 {
            return "Snack Pack"
        } else {
            return "Water Bottle"
        }
    }

    private func inferCategoryFromPosition(_ boundingBox: CGRect) -> MealCategory {
        let yPos = boundingBox.midY
        if yPos > 0.66 {
            return .lunch
        } else if yPos > 0.33 {
            return .snack
        } else {
            return .beverage
        }
    }

    // MARK: - Validation Logic

    private func validateItem(
        productName: String,
        compartment: CompartmentPosition?,
        expectedItems: [MealItem]
    ) -> DetectedItemResult.ValidationStatus {
        // Check if item is in manifest
        guard let expectedItem = expectedItems.first(where: { $0.name.lowercased().contains(productName.lowercased()) }) else {
            return .notExpected
        }

        // Check compartment (simplified - real logic would be more complex)
        guard let compartment = compartment else {
            return .wrongCompartment
        }

        // Validate compartment matches item category
        if !isCorrectCompartment(category: expectedItem.category, compartment: compartment) {
            return .wrongCompartment
        }

        return .correct
    }

    private func isCorrectCompartment(category: MealCategory, compartment: CompartmentPosition) -> Bool {
        // Map categories to compartments
        switch category {
        case .beverage:
            return compartment.row == .bottom // Beverages in bottom drawer
        case .snack:
            return compartment.row == .middle // Snacks in middle
        case .lunch, .dinner, .breakfast:
            return compartment.row == .top // Meals on top
        default:
            return true
        }
    }

    // MARK: - Helper Methods

    private func determineCompartment(for boundingBox: CGRect) -> CompartmentPosition? {
        // Determine which compartment based on Y position
        let yPosition = boundingBox.midY

        let row: CompartmentRow
        if yPosition < 0.33 {
            row = .top
        } else if yPosition < 0.66 {
            row = .middle
        } else {
            row = .bottom
        }

        // Determine column based on X position
        let xPosition = boundingBox.midX
        let column: CompartmentColumn
        if xPosition < 0.5 {
            column = .left
        } else {
            column = .right
        }

        return CompartmentPosition(row: row, column: column)
    }

    private func provideFeedback(for result: DetectedItemResult) {
        // Haptic feedback
        switch result.validationStatus {
        case .correct:
            HapticManager.shared.success()
        case .wrongCompartment, .wrongBatch:
            HapticManager.shared.warning()
        case .expired, .notExpected:
            HapticManager.shared.error()
        }

        // Accessibility announcement
        let announcement = "\(result.productName), \(result.validationStatus.message)"
        AccessibilityManager().announceForAccesibility(announcement)
    }

    private func checkCompletion() {
        let detectedCount = detectedItems.filter { $0.validationStatus == .correct }.count
        canComplete = detectedCount >= (manifest.totalItems / 2) // At least 50% detected
    }

    private func announceState() {
        AccessibilityManager().announceForAccesibility(sessionState.message)
    }

    // MARK: - Session Completion

    func completeSession() {
        print("📸 Completing AR session and generating analysis...")

        sessionState = .completed
        HapticManager.shared.success()

        // Generate mock MLX analysis if none exists
        if occupancyResult == nil {
            generateMockAnalysis()
        }

        // Wait a moment to show the analysis
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }

            // Create loading session
            let detectedMealItems = self.detectedItems.compactMap { result -> MealItem? in
                guard result.validationStatus == .correct else { return nil }
                return MealItem(name: result.productName, category: result.category, quantity: 1)
            }

            let session = LoadingSession(
                manifest: self.manifest,
                detectedItems: detectedMealItems,
                status: .completed
            )

            // Save to data service
            DataService.shared.completeSession(session)

            print("✅ Session completed and saved")
        }
    }

    /// Generates mock analysis results for demonstration
    private func generateMockAnalysis() {
        print("🎭 Generating mock MLX analysis results...")

        // Create mock detections based on manifest
        var mockDetections: [Detection] = []
        let totalItems = min(manifest.expectedItems.reduce(0) { $0 + $1.quantity }, 15)

        for i in 0..<totalItems {
            let normalizedY = Float.random(in: 0.2...0.8)
            let normalizedX = Float.random(in: 0.2...0.8)

            let detection = Detection(
                className: i % 3 == 0 ? "cookie" : (i % 2 == 0 ? "can" : "bottle_water"),
                confidence: Float.random(in: 0.7...0.95),
                boundingBox: Detection.BoundingBox(
                    x: normalizedX * 1920,
                    y: normalizedY * 1080,
                    width: Float.random(in: 80...150),
                    height: Float.random(in: 100...200)
                ),
                frame: Detection.FrameInfo(
                    width: 1920,
                    height: 1080
                )
            )
            mockDetections.append(detection)
        }

        // Generate mock occupancy result
        let mockOccupancy = trolleyModel.estimateVisualOccupancyHeuristic(
            detections: mockDetections,
            frameWidth: 1920,
            frameHeight: 1080
        )

        DispatchQueue.main.async { [weak self] in
            self?.detectedBeverages = mockDetections
            self?.occupancyResult = mockOccupancy
            self?.sessionState = .scanning // Show analysis overlay

            print("📊 Mock Analysis Generated:")
            print("  - Score: \(mockOccupancy.finalScore)/10")
            print("  - Category: \(mockOccupancy.category.rawValue)")
            print("  - Fill: \(mockOccupancy.fillPercent)%")
            print("  - Items: \(mockDetections.count)")
        }
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        print("🧹 Cleaning up AR resources")

        // Clear detection indicators
        clearDetectionIndicators()

        // Remove trolley anchor and entities
        trolleyAnchor?.removeFromParent()
        trolleyAnchor = nil
        cartEntity = nil

        // Clear detected items
        detectedItems.removeAll()
        currentDetection = nil

        // Clear MLX results
        occupancyResult = nil
        detectedBeverages.removeAll()

        // Clear vision handler
        visionRequestHandler = nil

        // Reset frame counter
        frameCounter = 0
        isProcessingFrame = false

        print("✅ Cleanup complete")
    }
    
    deinit {
        cleanup()
        print("♻️ ARTrolleyViewModel deinitialized")
    }
}

// MARK: - Supporting Types

struct CompartmentPosition: Equatable {
    let row: CompartmentRow
    let column: CompartmentColumn
}

enum CompartmentRow {
    case top
    case middle
    case bottom
}

enum CompartmentColumn {
    case left
    case right
    case center
}

// MARK: - SIMD Extensions

extension simd_float4 {
    var xyz: SIMD3<Float> {
        SIMD3<Float>(x, y, z)
    }
}
