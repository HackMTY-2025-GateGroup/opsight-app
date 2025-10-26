# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Opsight is an iOS/iPadOS app for **Gategroup airline catering warehouse operations**. The primary user is the **warehouse worker** who uses a tablet to manage the complete catering workflow: receiving inventory, preparing carts with FEFO (First Expire First Out) batch management, processing returned items from aircraft, and tracking waste. The app uses on-device computer vision to verify cart contents and detect anomalies.

**Target User:** Warehouse worker using tablet in catering facility

**Core Workflows:**
1. **Cart Preparation** - Load carts for flights using FEFO batch selection to minimize waste
2. **Return Processing** - Handle carts returned from aircraft, separate restock vs. waste items
3. **Inventory Management** - Track batches by expiration date (not just lot numbers)
4. **Waste Tracking** - Record and analyze waste to reduce losses (50% fill rule for opened items)

**Key Value Propositions:**
- FEFO batch management with 5-day expiration margin enforcement
- Mixed inventory handling (warehouse + aircraft returns)
- Historical usage analytics for demand prediction
- Client-specific cart requirements (updated every 4 months)
- Tablet-optimized interface with large touch targets
- Accessibility-first design (VoiceOver, haptics, Dynamic Type)
- Offline-first operation (all processing on-device)

## Building and Running

This is a standard Xcode iOS project.

**Build the project:**
```bash
cd /Users/ntonio/tonojects/Opsight
xcodebuild -scheme Opsight -configuration Debug build
```

**Open in Xcode:**
```bash
open Opsight.xcodeproj
```

**Run on simulator:** Use Xcode's run button (Cmd+R) or:
```bash
xcodebuild -scheme Opsight -destination 'platform=iOS Simulator,name=iPhone 15' test
```

## Architecture

### Core Design Pattern: SwiftUI + MVVM

The app follows SwiftUI best practices with a clear separation of concerns:

**Models** (`Models/`) - Pure data structures representing domain entities:

*Core Warehouse Operations:*
- `ProductBatch` - Batch/lot tracking with expiration dates, FEFO scoring
- `CartManifest` - Flight cart requirements with batch assignments and client specifications
- `ReturnedCart` & `ReturnedItem` - Processing items returned from aircraft
- `WasteRecord` - Comprehensive waste tracking with reasons and sources
- `ProductUsageHistory` - Historical consumption patterns for demand prediction

*Inventory Management:*
- `Product` - Product master data with categories and shelf life
- `Inventory` - Location-based inventory (warehouse, trolley, aircraft, lounge)
- `InventoryItem` - Stock levels with batch tracking and expiration
- `InventoryMovement` - Movement tracking for audit trail

*Flight Operations:*
- `Flight`, `LoadingSession` - Core business entities for flight/cart operations
- `MealItem` - Items to be loaded on carts, with categories and quantities
- `Aircraft`, `Trolley` - Supporting entities from the database schema

Models include computed properties for presentation and business logic (e.g., `daysUntilExpiry`, `fefoScore`, `dispositionRecommendation`)

**Views** (`Views/`) - SwiftUI views organized by feature:

*Warehouse Workflows (Tablet-Optimized):*
- `WarehouseWorkflowView` - Main interface with workflow selector
- `CartPreparationWorkflow` - FEFO-guided cart loading with batch recommendations
- `ReturnProcessingWorkflow` - Handle aircraft returns, separate restock vs. waste
- `InventoryCheckWorkflow` - Verify stock levels and expiration dates
- `WasteRecordingWorkflow` - Document waste with reasons and values

*Supporting Views:*
- `HomeView`, `HistoryView`, `SettingsView` - Dashboard and navigation
- `CameraView` - Camera interface for scanning (MLX integration)
- Reusable components: `BatchRecommendationRow`, `CartItemCard`, `FlightSelectionCard`
- All views optimized for tablet with large touch targets (44x44pt minimum)

**Services** (`Services/`) - Shared singleton managers:
- `AccessibilityManager` - Monitors VoiceOver state, announces accessibility messages
- `HapticManager` - Provides haptic feedback (success, error, warning, selection, impact)

**App Entry** - `OpsightApp.swift` sets up the app with environment objects

### Key Architectural Patterns

**Accessibility Integration:**
- `AccessibilityManager` is injected as `@EnvironmentObject` throughout the view hierarchy
- All interactive elements have proper `.accessibilityLabel()`, `.accessibilityHint()`, and `.accessibilityElement()` modifiers
- VoiceOver announcements via `announceForAccesibility()` for dynamic feedback
- Haptic feedback parallels visual feedback for non-visual confirmation

**Data Flow:**
- Currently uses `@State` for local view state and sample data generation
- Models calculate derived state (e.g., `LoadingSession` auto-calculates accuracy, missing/extra items in initializer)
- Future: Will integrate Core Data for persistence and CloudKit for sync

**Core Business Logic:**

*FEFO Batch Management:*
The system prioritizes batches to minimize waste:
1. Sort available batches by `expirationDate` (earliest first)
2. Apply 5-day expiration margin - batches expiring <5 days flagged as critical
3. Assign batches to cart manifests with visual indicators (green/orange/red)
4. Block usage of expired batches, alert on critical batches

*Cart Loading Verification:*
The `LoadingSession` model contains verification algorithm:
1. Compares `manifest.expectedItems` against `detectedItems`
2. Validates batch assignments match FEFO recommendations
3. Calculates `missingItems` and `extraItems`
4. Detects anomalies (wrong batch, expired product, damaged items)
5. Computes accuracy: `(totalExpected - totalMissing - totalExtra) / totalExpected`

*Return Processing Logic:*
1. Scan returned cart items
2. Apply 50% rule: opened items >50% full → restock, ≤50% → dispose
3. Check expiration dates: within margin → restock, expired → waste
4. Record waste with reason, value, and source
5. Update inventory for restocked items

*Usage Analytics:*
Track historical consumption to optimize future cart loading:
- `utilizationRate` = actual consumption / expected quantity
- Identify high performers (>80% utilization) for potential stock increase
- Flag low performers (<30% utilization) for reduction
- Aggregate by route, class of service, product category

## Development Workflow

**Current MVP Phase:**
- Focus on warehouse worker tablet interface
- FEFO batch management and recommendations
- Waste tracking and return processing workflows
- Using mock/sample data for demonstrations
- Camera integration is placeholder (shows sheet but no actual capture)

**Next Phase (Post-Hackathon):**
- Integrate AVFoundation for camera capture
- Add MLX for on-device object detection and expiration date OCR
- Implement Core Data for local persistence
- Add real-time detection overlay during scanning
- Complete ReturnProcessing, InventoryCheck, and WasteRecording workflows
- Integrate usage analytics dashboard with historical trends
- Add client requirements management (4-month rotation)

## Important Implementation Notes

**Accessibility Requirements:**
- ALL new UI elements must include accessibility labels and hints
- Test all features with VoiceOver enabled
- Ensure minimum touch target size of 44x44 points
- Support Dynamic Type for all text
- Use haptic feedback to complement visual state changes

**Haptic Feedback Guidelines:**
- Success state: `HapticManager.shared.success()`
- Error state: `HapticManager.shared.error()`
- Warning state: `HapticManager.shared.warning()`
- Selection/interaction: `HapticManager.shared.selection()`
- Button taps: `HapticManager.shared.impact()`

**Sample Data Pattern:**
When creating sample/mock data for development or demos, follow the pattern in `HomeView.loadTodaySessions()`:
```swift
let sampleManifest = CartManifest(
    flightNumber: "AA123",
    destination: "LAX",
    expectedItems: [
        MealItem(name: "Chicken Meal", category: .lunch, quantity: 45),
        MealItem(name: "Vegetarian Meal", category: .lunch, quantity: 15)
    ],
    totalPassengers: 60,
    departureTime: Date().addingTimeInterval(7200)
)
```

**Model Initialization:**
- Most models have default parameter values for ease of testing
- `LoadingSession` auto-calculates accuracy and mismatches on initialization
- Use provided computed properties for formatted presentation (e.g., `formattedFlightNumber`, `departureTime`)

## Future ML Integration (In Development)

The vision system will use:
- **AVFoundation** - Real-time camera capture
- **Vision Framework** - Image analysis and object detection
- **MLX** - On-device ML inference for:
  - Product classification and counting
  - Expiration date OCR (critical for FEFO)
  - Fill level detection for opened beverages (50% rule)
  - Damage/quality assessment
- Real-time detection overlay showing bounding boxes and confidence scores
- Batch detection mode for final cart verification
- Anomaly detection (wrong batch, expired, out of place items)

**Note:** MLX Swift package is added to project but not yet linked to target. See TestMLX.swift for integration testing.

## Key Files Reference

**Core Models:**
- `Models/ProductBatch.swift` - Batch tracking with FEFO logic
- `Models/CartManifest.swift` - Flight requirements with batch assignments and client specs
- `Models/ReturnedCart.swift` - Aircraft return processing with 50% rule
- `Models/WasteRecord.swift` - Comprehensive waste tracking
- `Models/ProductUsageHistory.swift` - Historical analytics for demand prediction

**Warehouse Views:**
- `Views/WarehouseWorkflowView.swift` - Main tablet interface with workflow selector
- `Views/CartPreparationWorkflow` - FEFO-guided cart loading
- `Views/HomeView.swift` - Dashboard with stats and recent activity

**Services:**
- `Services/AccessibilityManager.swift` - Accessibility announcements
- `Services/HapticManager.swift` - Haptic feedback for all interactions
- `Services/DataService.swift` - Shared data management

**Configuration:**
- `OpsightApp.swift` - App entry with environment setup
- `ContentView.swift` - Tab-based navigation structure
- `TestMLX.swift` - MLX integration testing (package not yet linked)

**Documentation:**
- `CONCEPT.md` - Full product vision, features, and roadmap
- `CLAUDE.md` - This file - development guide

## Warehouse Operation Notes (from Client)

**Gategroup Process Requirements:**
1. Client requirements change every 4 months based on consumer data
2. Products received by batch/lot with shared expiration dates
3. Workers naturally read dates, not lot numbers - display both
4. FEFO critical: items expiring first must be loaded first
5. 5-day expiration margin before product is considered too close
6. Mixed inventory: warehouse items + returned aircraft items must be separated
7. 50% fill rule: opened beverages >50% can be restocked, ≤50% are waste
8. System must detect anomalies: wrong batch, expired, out of place
9. Historical data predicts which products sell well vs. waste
10. Extra passengers must be accounted for in manifest
11. Tablet interface shows worker what to load and from which batch
12. Retail operations track exact sales; catering estimates distribution %
