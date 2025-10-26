# ARKit + MLX Trolley Box Integration Plan

## Overview
Create an AR-based trolley visualization system that uses ARKit for spatial tracking and MLX for on-device object detection and expiration date recognition.

---

## Architecture

### 1. ARKit Component (Spatial Tracking & Visualization)

**Purpose:** Create a virtual 3D trolley/cart in AR space where detected items are placed

**Implementation:**
```swift
// ARTrolleyView.swift
import SwiftUI
import RealityKit
import ARKit

struct ARTrolleyView: View {
    @StateObject private var arViewModel = ARTrolleyViewModel()

    var body: some View {
        ZStack {
            // AR Camera view with RealityKit
            ARViewContainer(viewModel: arViewModel)
                .edgesIgnoringSafeArea(.all)

            // Overlay UI
            VStack {
                // Top: Cart info
                CartInfoOverlay(manifest: arViewModel.currentManifest)

                Spacer()

                // Bottom: Controls and detected items
                ARControlsOverlay(viewModel: arViewModel)
            }
        }
    }
}
```

**Key Features:**
- **Virtual Trolley Model:** 3D model of airline cart with compartments
- **Plane Detection:** Detect floor/table surface to anchor trolley
- **Item Placement:** As items are detected, they appear in the virtual cart
- **Spatial Audio:** Confirmation sounds when item placed correctly
- **Visual Indicators:** Green checkmarks for correct items, red X for wrong items

---

### 2. MLX Component (On-Device ML Inference)

**Purpose:** Real-time object detection and OCR for expiration dates

**Models Needed:**
1. **Object Detection Model** - Identify products (meals, beverages, snacks)
2. **OCR Model** - Read expiration dates from packaging
3. **Fill Level Detector** - Estimate how full opened beverages are (for 50% rule)

**Implementation:**
```swift
// MLXVisionService.swift
import MLX
import MLXRandom
import Vision
import CoreML

class MLXVisionService: ObservableObject {
    @Published var detectedItems: [DetectedItem] = []
    @Published var isProcessing = false

    // MLX models
    private var objectDetectionModel: Any? // MLX model
    private var ocrModel: Any? // MLX model for date recognition
    private var fillLevelModel: Any? // MLX model for liquid detection

    func processFrame(_ pixelBuffer: CVPixelBuffer) {
        isProcessing = true

        // 1. Object Detection
        let detectedObjects = runObjectDetection(pixelBuffer)

        // 2. For each detected object, run OCR for expiration date
        for object in detectedObjects {
            if object.hasVisibleDate {
                let expirationDate = runOCR(object.boundingBox, in: pixelBuffer)
                object.expirationDate = expirationDate
            }
        }

        // 3. For beverages, estimate fill level
        for object in detectedObjects where object.category == .beverage {
            let fillLevel = estimateFillLevel(object.boundingBox, in: pixelBuffer)
            object.fillLevel = fillLevel
        }

        detectedItems = detectedObjects
        isProcessing = false
    }

    private func runObjectDetection(_ pixelBuffer: CVPixelBuffer) -> [DetectedItem] {
        // MLX inference for object detection
        // Returns: product type, bounding box, confidence
    }

    private func runOCR(_ region: CGRect, in pixelBuffer: CVPixelBuffer) -> Date? {
        // MLX OCR model to extract date text
        // Parse and return Date object
    }

    private func estimateFillLevel(_ region: CGRect, in pixelBuffer: CVPixelBuffer) -> Double {
        // MLX model to detect liquid level
        // Returns 0.0 to 1.0
    }
}
```

---

### 3. Combined AR + ML Workflow

**Step-by-Step Process:**

#### Phase 1: Setup
1. Worker selects flight from manifest
2. AR session starts, searches for horizontal plane
3. Virtual trolley appears on detected surface
4. Trolley shows expected compartments based on manifest

#### Phase 2: Scanning Loop
1. **Camera captures frame** → Send to MLX
2. **MLX detects item** → Extract product type, expiration date, fill level
3. **Validate against manifest:**
   - Check if item is expected
   - Verify batch has correct expiration date (FEFO)
   - For opened items, check 50% rule
4. **Place in AR trolley:**
   - Correct items → Green, placed in correct compartment
   - Wrong items → Red, highlighted as error
   - Expired items → Flashing red, blocked from placement
5. **Update progress** → Show completion percentage

#### Phase 3: Completion
1. All items scanned → Show summary
2. Missing items highlighted in trolley (empty compartments)
3. Extra items shown separately
4. Generate LoadingSession with results

---

## File Structure

```
Opsight/
├── AR/
│   ├── ARTrolleyView.swift           // Main AR interface
│   ├── ARTrolleyViewModel.swift      // AR state management
│   ├── ARViewContainer.swift         // RealityKit wrapper
│   ├── TrolleyEntity.swift           // 3D trolley model
│   └── ItemPlacementLogic.swift      // Item positioning in AR
│
├── MLX/
│   ├── MLXVisionService.swift        // Main ML service
│   ├── ObjectDetectionModel.swift    // Product detection
│   ├── ExpirationOCRModel.swift      // Date reading
│   ├── FillLevelModel.swift          // Liquid estimation
│   └── Models/                       // MLX model files
│       ├── product_detector.mlx
│       ├── expiration_ocr.mlx
│       └── fill_estimator.mlx
│
├── Views/
│   ├── CartInfoOverlay.swift         // AR UI overlay
│   ├── ARControlsOverlay.swift       // Scan controls
│   └── ARResultsView.swift           // Final results
│
└── Models/
    ├── DetectedItem.swift            // Detected product model
    └── ARScanSession.swift           // AR session state
```

---

## Detailed Implementation Steps

### Step 1: Create AR Foundation
```swift
// ARTrolleyViewModel.swift
import ARKit
import RealityKit

class ARTrolleyViewModel: NSObject, ObservableObject {
    @Published var arView: ARView?
    @Published var trolleyAnchor: AnchorEntity?
    @Published var currentManifest: CartManifest?
    @Published var detectedItems: [DetectedItem] = []
    @Published var sessionState: ARSessionState = .initializing

    private var mlxService = MLXVisionService()

    enum ARSessionState {
        case initializing
        case searchingForSurface
        case trolleyPlaced
        case scanning
        case completed
    }

    func startARSession(for manifest: CartManifest) {
        currentManifest = manifest
        sessionState = .searchingForSurface

        // Configure AR session
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic

        arView?.session.run(config)
    }

    func placeTrolley(at anchor: ARAnchor) {
        guard let trolley = createTrolleyEntity() else { return }

        let anchorEntity = AnchorEntity(anchor: anchor)
        anchorEntity.addChild(trolley)
        arView?.scene.addAnchor(anchorEntity)

        trolleyAnchor = anchorEntity
        sessionState = .scanning
    }

    private func createTrolleyEntity() -> ModelEntity? {
        // Create 3D trolley model
        // Add compartments based on manifest
        // Return ModelEntity
    }

    func processFrame(_ frame: ARFrame) {
        // Extract pixel buffer from AR frame
        let pixelBuffer = frame.capturedImage

        // Send to MLX for detection
        mlxService.processFrame(pixelBuffer)
    }

    func addDetectedItem(_ item: DetectedItem) {
        // Validate against manifest
        let validation = validateItem(item)

        // Create 3D representation in trolley
        placeItemInTrolley(item, validation: validation)

        detectedItems.append(item)

        // Check if complete
        if isCartComplete() {
            sessionState = .completed
        }
    }
}
```

### Step 2: Create MLX Service
```swift
// MLXVisionService.swift
import MLX
import Vision

class MLXVisionService: ObservableObject {
    @Published var currentDetection: DetectedItem?

    func processFrame(_ pixelBuffer: CVPixelBuffer) {
        DispatchQueue.global(qos: .userInteractive).async {
            // 1. Run object detection
            let detections = self.detectObjects(in: pixelBuffer)

            // 2. For each detection, extract metadata
            for detection in detections {
                // Run OCR if package visible
                if detection.hasText {
                    detection.expirationDate = self.extractExpirationDate(
                        from: pixelBuffer,
                        region: detection.boundingBox
                    )

                    // Parse batch number
                    detection.batchNumber = self.extractBatchNumber(
                        from: pixelBuffer,
                        region: detection.boundingBox
                    )
                }

                // Estimate fill level for beverages
                if detection.isBeverage {
                    detection.fillLevel = self.estimateFillLevel(
                        from: pixelBuffer,
                        region: detection.boundingBox
                    )
                }

                DispatchQueue.main.async {
                    self.currentDetection = detection
                }
            }
        }
    }

    private func detectObjects(in pixelBuffer: CVPixelBuffer) -> [DetectedItem] {
        // MLX object detection inference
        // Use YOLOv8 or similar trained on catering products
    }

    private func extractExpirationDate(from pixelBuffer: CVPixelBuffer, region: CGRect) -> Date? {
        // Crop to region
        // Run MLX OCR model
        // Parse date string (various formats: MM/DD/YYYY, DD-MM-YY, etc.)
    }

    private func extractBatchNumber(from pixelBuffer: CVPixelBuffer, region: CGRect) -> String? {
        // Similar to expiration date extraction
    }

    private func estimateFillLevel(from pixelBuffer: CVPixelBuffer, region: CGRect) -> Double {
        // ML model trained to detect liquid levels in bottles
        // Returns percentage (0.0 to 1.0)
    }
}
```

### Step 3: Create AR UI Overlay
```swift
// CartInfoOverlay.swift
struct CartInfoOverlay: View {
    let manifest: CartManifest?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let manifest = manifest {
                HStack {
                    Image(systemName: "airplane")
                    Text("Flight \(manifest.flightNumber)")
                        .font(.headline)
                    Spacer()
                    Text("\(manifest.destination)")
                        .font(.subheadline)
                }

                ProgressView(value: completionPercentage)
                    .progressViewStyle(.linear)

                Text("\(itemsLoaded)/\(manifest.totalItems) items loaded")
                    .font(.caption)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .padding()
    }
}
```

---

## Key Technologies

### ARKit Features:
- **World Tracking** - Track device position in 3D space
- **Plane Detection** - Find horizontal surfaces for trolley placement
- **Anchors** - Lock trolley to physical space
- **RealityKit** - Render 3D trolley with lighting

### MLX Features:
- **On-Device Inference** - No cloud, fast processing
- **Object Detection** - Identify products in frame
- **OCR** - Read text from packaging
- **Custom Models** - Train on specific product catalog

---

## User Experience Flow

```
1. Start AR Session
   ↓
2. "Find a flat surface..."
   → User points camera at table/floor
   ↓
3. "Tap to place trolley"
   → Virtual cart appears
   ↓
4. "Start scanning items..."
   → Camera feed processes in real-time
   ↓
5. Item Detected
   → Beep sound
   → Item appears in trolley
   → Check/X indicator
   ↓
6. Continue scanning
   → Progress bar updates
   → Missing items highlighted
   ↓
7. Complete
   → Summary view
   → Save session
```

---

## FEFO Integration

As items are scanned:
1. **Extract expiration date** via OCR
2. **Check against batch assignments** in manifest
3. **Visual feedback:**
   - ✅ Green: Correct batch, within 5-day margin
   - ⚠️ Orange: Expires in 5-7 days (acceptable but warning)
   - ❌ Red: Wrong batch or expired
4. **Block placement** if batch is incorrect
5. **Suggest correct batch** from warehouse

---

## Benefits of This Approach

1. **Intuitive Interface** - Workers see exactly where items go
2. **Real-Time Feedback** - Immediate validation
3. **Hands-Free** - Just point camera, no manual input
4. **Accurate Tracking** - Computer vision reduces human error
5. **Training Tool** - New workers learn cart layout visually
6. **Accessibility** - VoiceOver announces each detected item
7. **Offline** - All processing on-device with MLX

---

## Next Steps

1. **Link MLX package to Xcode target** (currently not linked)
2. **Train MLX models** on product catalog
3. **Create 3D trolley model** in Reality Composer
4. **Implement ARTrolleyView** with RealityKit
5. **Integrate with existing CartManifest** system
6. **Test with real catering products**

---

## Model Training Requirements

### Object Detection Model
- **Dataset:** 5000+ images of catering products
- **Classes:** Meals, beverages, snacks, canned goods, etc.
- **Annotations:** Bounding boxes with product categories
- **Framework:** YOLOv8 exported to MLX format

### OCR Model
- **Dataset:** Images of product labels with dates
- **Focus:** Date patterns (MM/DD/YYYY, etc.) and batch numbers
- **Framework:** Custom transformer model in MLX

### Fill Level Model
- **Dataset:** Images of bottles at various fill levels
- **Output:** Percentage (0.0 to 1.0)
- **Training:** Supervised learning with labeled fill levels
