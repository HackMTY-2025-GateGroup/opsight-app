//
//  ARTrolleyView.swift
//  Opsight
//
//  Created by toño on 25/10/25.
//

import SwiftUI
import ARKit
import RealityKit

/// Main AR view for scanning trolley carts
/// Flow: Camera → Show positioning instructions → Detect cart → Overlay AR model → Validate item placement
struct ARTrolleyView: View {
    @EnvironmentObject var accessibilityManager: AccessibilityManager
    @StateObject private var viewModel: ARTrolleyViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var cameraPermission = CameraPermissionManager.shared

    @State private var currentGestureRotation: Angle = .zero
    @State private var showPermissionView = false

    init(manifest: CartManifest) {
        _viewModel = StateObject(wrappedValue: ARTrolleyViewModel(manifest: manifest))
    }

    var body: some View {
        ZStack {
            if showPermissionView {
                // Show permission request view
                CameraPermissionView {
                    showPermissionView = false
                    viewModel.startARSession()
                }
            } else {
                ZStack {
                    // AR Camera View
                    ARViewContainer(viewModel: viewModel)
                        .edgesIgnoringSafeArea(.all)

                    // UI Overlays (allow hits for buttons, but transparent areas pass through)
                    VStack {
                        // Top: Status and progress
                        topOverlay

                        Spacer()
                            .contentShape(Rectangle())
                            .allowsHitTesting(false) // Spacer doesn't block taps

                        // Middle: MLX Occupancy Results (when scanning or completed)
                        if (viewModel.sessionState == .scanning || viewModel.sessionState == .completed),
                           let occupancy = viewModel.occupancyResult {
                            occupancyResultsOverlay(occupancy: occupancy)
                        }

                        Spacer()
                            .contentShape(Rectangle())
                            .allowsHitTesting(false) // Spacer doesn't block taps

                        // Bottom: Controls and feedback
                        bottomOverlay
                    }

                    // Gesture instructions overlay
                    if viewModel.sessionState == .cartPlaced || viewModel.sessionState == .scanning {
                        gestureInstructionsOverlay
                    }
                }
            }
        }
        .onAppear {
            // Check camera permission before starting AR
            cameraPermission.ensurePermission { granted in
                if granted {
                    viewModel.startARSession()
                } else {
                    showPermissionView = true
                }
            }
        }
        .onDisappear {
            viewModel.pauseARSession()
        }
    }
    
    // MARK: - Gestures
    
    private var simultaneousGestures: some Gesture {
        SimultaneousGesture(
            dragGesture,
            SimultaneousGesture(
                rotationGesture,
                tapGesture
            )
        )
    }
    
    private var tapGesture: some Gesture {
        SpatialTapGesture()
            .onEnded { value in
                // Only handle tap if cart not placed yet
                if viewModel.sessionState == .surfaceDetected {
                    viewModel.handleTap(at: value.location)
                }
            }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 15, coordinateSpace: .global)
            .onChanged { value in
                // Only allow dragging if cart is placed
                if viewModel.sessionState == .cartPlaced || viewModel.sessionState == .scanning {
                    viewModel.handleDrag(to: value.location)
                    HapticManager.shared.selection()
                }
            }
            .onEnded { _ in
                HapticManager.shared.impact()
            }
    }

    private var rotationGesture: some Gesture {
        RotationGesture(minimumAngleDelta: .degrees(5))
            .onChanged { angle in
                // Only allow rotation if cart is placed
                if viewModel.sessionState == .cartPlaced || viewModel.sessionState == .scanning {
                    let deltaAngle = angle - currentGestureRotation
                    currentGestureRotation = angle
                    viewModel.handleRotation(angle: deltaAngle)
                }
            }
            .onEnded { angle in
                viewModel.commitRotation(angle: currentGestureRotation)
                currentGestureRotation = .zero
            }
    }

    // MARK: - Top Overlay

    private var topOverlay: some View {
        VStack(spacing: 12) {
            // Close button and status
            HStack {
                Button(action: {
                    HapticManager.shared.impact()
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Close AR scanner")

                Spacer()

                // Simple status indicator
                HStack(spacing: 8) {
                    Image(systemName: viewModel.sessionState.icon)
                        .foregroundColor(viewModel.sessionState.color)
                    Text(viewModel.sessionState.message)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
            }
        }
        .padding()
    }

    // MARK: - Bottom Overlay

    private var bottomOverlay: some View {
        VStack(spacing: 16) {
            // Capture button when cart is placed or scanning
            if viewModel.sessionState == .cartPlaced || viewModel.sessionState == .scanning {
                Button(action: {
                    HapticManager.shared.success()
                    viewModel.completeSession()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                        Text("Capture Photo")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.blue)
                    .cornerRadius(16)
                }
                .accessibilityLabel("Capture cart photo")
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }

            // Done button when completed
            if viewModel.sessionState == .completed {
                Button(action: {
                    HapticManager.shared.success()
                    dismiss()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                        Text("Done")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.green)
                    .cornerRadius(16)
                }
                .accessibilityLabel("Finish and return")
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - MLX Occupancy Results Overlay

    private func occupancyResultsOverlay(occupancy: VisualOccupancyResult) -> some View {
        VStack(spacing: 12) {
            // Occupancy Score Card
            HStack(spacing: 16) {
                // Score badge
                ZStack {
                    Circle()
                        .fill(categoryColor(occupancy.category))
                        .frame(width: 60, height: 60)

                    VStack(spacing: 2) {
                        Text(String(format: "%.1f", occupancy.finalScore))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("/ 10")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                // Details
                VStack(alignment: .leading, spacing: 6) {
                    Text(occupancy.category.rawValue.uppercased())
                        .font(.headline)
                        .foregroundColor(.white)

                    HStack(spacing: 12) {
                        Label("\(Int(occupancy.fillPercent))%", systemImage: "square.fill")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))

                        Label("\(occupancy.detectionCount)", systemImage: "cube.box.fill")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                    }

                    if occupancy.snackPercent > 0 {
                        Text("🍪 \(Int(occupancy.snackPercent))% snacks")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                Spacer()
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .shadow(radius: 5)

            // Visual Breakdown (Compact)
            HStack(spacing: 8) {
                // Fill indicator
                VStack(spacing: 4) {
                    ProgressView(value: Double(occupancy.fillPercent) / 100.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .cyan))
                        .frame(width: 80)
                    Text("Fill")
                        .font(.caption2)
                        .foregroundColor(.white)
                }

                // Vertical score indicator
                VStack(spacing: 4) {
                    ProgressView(value: Double(occupancy.verticalScore) / 10.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .green))
                        .frame(width: 80)
                    Text("Packing")
                        .font(.caption2)
                        .foregroundColor(.white)
                }

                // Top ratio indicator
                VStack(spacing: 4) {
                    ProgressView(value: Double(occupancy.topRatio))
                        .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                        .frame(width: 80)
                    Text("Top")
                        .font(.caption2)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
        .padding(.horizontal)
        .transition(.move(edge: .trailing).combined(with: .opacity))
        .animation(.easeInOut, value: occupancy.finalScore)
    }

    private func categoryColor(_ category: OccupancyCategory) -> Color {
        switch category {
        case .empty: return .gray
        case .sparse: return .red
        case .partial: return .orange
        case .good: return .yellow
        case .nearlyFull: return .green
        case .full: return .cyan
        }
    }
    
    // MARK: - Gesture Instructions Overlay
    
    private var gestureInstructionsOverlay: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 20) {
                // Drag instruction
                HStack(spacing: 8) {
                    Image(systemName: "hand.draw")
                        .font(.caption)
                    Text("Drag to move")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
                
                // Rotate instruction
                HStack(spacing: 8) {
                    Image(systemName: "rotate.right")
                        .font(.caption)
                    Text("Pinch to rotate")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .cornerRadius(8)
            }
            .padding(.bottom, 120)
        }
        .transition(.opacity)
        .animation(.easeInOut, value: viewModel.sessionState)
    }
}

// MARK: - Status Card

struct StatusCard: View {
    let state: ARSessionState
    let manifest: CartManifest

    var body: some View {
        HStack {
            Image(systemName: state.icon)
                .font(.title3)
                .foregroundColor(state.color)

            VStack(alignment: .leading, spacing: 2) {
                Text(state.message)
                    .font(.headline)
                Text("Flight \(manifest.flightNumber) → \(manifest.destination)")
                    .font(.caption)
            }

            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(state.message). Flight \(manifest.flightNumber)")
    }
}

// MARK: - Progress Bar

struct ProgressBar: View {
    let detected: Int
    let total: Int

    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(detected) / Double(total)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Progress")
                    .font(.subheadline)
                    .foregroundColor(.white)
                Spacer()
                Text("\(detected)/\(total)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 8)
                        .cornerRadius(4)

                    // Progress
                    Rectangle()
                        .fill(Color.green)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .cornerRadius(4)
                        .animation(.easeInOut, value: progress)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Progress: \(detected) of \(total) items detected")
    }
}

// MARK: - Detection Feedback Card

struct DetectionFeedbackCard: View {
    let item: DetectedItemResult

    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            ZStack {
                Circle()
                    .fill(item.validationStatus.color.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: item.validationStatus.icon)
                    .font(.title2)
                    .foregroundColor(item.validationStatus.color)
            }

            // Item info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.productName)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(item.validationStatus.message)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))

                if let expirationDate = item.expirationDate {
                    Text("Expires: \(formattedDate(expirationDate))")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            Spacer()

            // Confidence indicator
            VStack(spacing: 2) {
                Text("\(Int(item.confidence * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text("confident")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
        .background(item.validationStatus.color.opacity(0.8))
        .cornerRadius(12)
        .shadow(radius: 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.productName), \(item.validationStatus.message)")
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - AR View Container

struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var viewModel: ARTrolleyViewModel

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        // Configure AR session with minimal settings for better performance
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]

        // Disable heavy features for better performance
        config.environmentTexturing = .none

        // Reduce world tracking quality for better performance on older devices
        if #available(iOS 16.0, *) {
            config.videoFormat = ARWorldTrackingConfiguration.recommendedVideoFormatFor4KResolution ?? ARWorldTrackingConfiguration.supportedVideoFormats[0]
        }

        // Don't start session immediately - let viewModel control it
        arView.session.delegate = context.coordinator
        viewModel.arView = arView

        // Store coordinator reference for plane visualization
        context.coordinator.arView = arView
        context.coordinator.config = config

        // Add tap gesture recognizer for trolley placement
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // Updates handled by view model
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    class Coordinator: NSObject, ARSessionDelegate {
        let viewModel: ARTrolleyViewModel
        weak var arView: ARView?
        var config: ARWorldTrackingConfiguration?
        private var planeEntities: [UUID: AnchorEntity] = [:]
        private let maxPlaneVisualizations = 3 // Limit visualizations for performance

        init(viewModel: ARTrolleyViewModel) {
            self.viewModel = viewModel
        }

        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            // Process each frame (throttled in viewModel)
            viewModel.processFrame(frame)
        }

        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            for anchor in anchors {
                if let planeAnchor = anchor as? ARPlaneAnchor {
                    // Notify view model
                    viewModel.handlePlaneDetection(planeAnchor)

                    // Only add visual plane if we haven't hit the limit
                    if planeEntities.count < maxPlaneVisualizations {
                        addPlaneVisualization(for: planeAnchor)
                    }
                }
            }
        }

        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            for anchor in anchors {
                if let planeAnchor = anchor as? ARPlaneAnchor {
                    // Notify view model
                    viewModel.handlePlaneUpdate(planeAnchor)

                    // Only update if we're visualizing this plane
                    if planeEntities[planeAnchor.identifier] != nil {
                        updatePlaneVisualization(for: planeAnchor)
                    }
                }
            }
        }

        func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
            for anchor in anchors {
                if let planeAnchor = anchor as? ARPlaneAnchor {
                    // Notify view model
                    viewModel.handlePlaneRemoval(planeAnchor)

                    // Remove visual plane representation if exists
                    removePlaneVisualization(for: planeAnchor)
                }
            }
        }
        
        func session(_ session: ARSession, didFailWithError error: Error) {
            print("❌ AR Session failed: \(error.localizedDescription)")
            viewModel.handleSessionError(error)
        }
        
        func sessionWasInterrupted(_ session: ARSession) {
            print("⚠️ AR Session interrupted")
            viewModel.sessionState = .paused
        }
        
        func sessionInterruptionEnded(_ session: ARSession) {
            print("✅ AR Session resumed")
            // Restart session with stored config
            if let config = config {
                session.run(config, options: [.resetTracking, .removeExistingAnchors])
            }
        }

        // MARK: - Tap Gesture Handler

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = arView else { return }

            // Get tap location in ARView
            let tapLocation = gesture.location(in: arView)

            print("👆 Tap detected at: \(tapLocation)")

            // Pass to view model
            viewModel.handleTap(at: tapLocation)
        }

        // MARK: - Plane Visualization

        private func addPlaneVisualization(for planeAnchor: ARPlaneAnchor) {
            guard let arView = arView else { return }
            
            // Only add if plane is large enough (50cm x 50cm)
            let extent = planeAnchor.planeSize
            guard extent.width > 0.5 && extent.height > 0.5 else { return }

            // Create anchor entity
            let anchorEntity = AnchorEntity(anchor: planeAnchor)

            // Create simplified plane mesh
            let planeEntity = PlaneVisualization.createPlaneEntity(for: planeAnchor)
            anchorEntity.addChild(planeEntity)

            // Add to scene
            arView.scene.addAnchor(anchorEntity)

            // Store reference
            planeEntities[planeAnchor.identifier] = anchorEntity

            print("✅ Added plane visualization: \(planeAnchor.identifier) - \(extent.width)x\(extent.height)m")
        }

        private func updatePlaneVisualization(for planeAnchor: ARPlaneAnchor) {
            guard let anchorEntity = planeEntities[planeAnchor.identifier] else { return }
            guard let planeEntity = anchorEntity.children.first as? ModelEntity else { return }

            // Update plane mesh to match new extent
            PlaneVisualization.updatePlaneEntity(planeEntity, for: planeAnchor)
        }

        private func removePlaneVisualization(for planeAnchor: ARPlaneAnchor) {
            guard let anchorEntity = planeEntities[planeAnchor.identifier] else { return }

            // Remove from scene
            anchorEntity.removeFromParent()

            // Remove from dictionary
            planeEntities.removeValue(forKey: planeAnchor.identifier)

            print("❌ Removed plane visualization: \(planeAnchor.identifier)")
        }
        
        deinit {
            // Clean up all plane entities
            for (_, entity) in planeEntities {
                entity.removeFromParent()
            }
            planeEntities.removeAll()
        }
    }
}

#Preview {
    ARTrolleyView(manifest: CartManifest(
        flightNumber: "AA123",
        destination: "LAX",
        departureTime: Date().addingTimeInterval(3600),
        totalPassengers: 150,
        expectedItems: [
            MealItem(name: "Water Bottle", category: .beverage, quantity: 10),
            MealItem(name: "Snack Pack", category: .snack, quantity: 8)
        ]
    ))
    .environmentObject(AccessibilityManager())
}
