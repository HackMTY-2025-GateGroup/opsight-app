# Opsight - Airline Catering Operations Management

**Opsight** (Operations + Insight) is an iOS/iPadOS application designed for Gategroup airline catering warehouse operations. The app streamlines the complete catering workflow with intelligent batch management, waste reduction, and on-device computer vision for cart verification.

## Overview

Opsight empowers warehouse workers with a tablet-optimized interface to manage inventory receiving, cart preparation with FEFO (First Expire First Out) logic, aircraft return processing, and comprehensive waste tracking. The system uses on-device ML to verify cart contents and detect anomalies, ensuring accuracy while minimizing food waste.

### Target Users

- **Primary:** Warehouse workers using tablets in catering facilities
- **Secondary:** Operations managers monitoring performance and waste metrics

### Key Features

- **FEFO Batch Management** - Intelligent batch selection with 5-day expiration margin enforcement to minimize waste
- **Cart Preparation Workflow** - Load carts for flights with real-time batch recommendations and verification
- **Return Processing** - Handle aircraft returns with 50% fill rule (restock vs. waste decisions)
- **Waste Tracking** - Comprehensive waste recording with reasons, sources, and value tracking
- **Inventory Management** - Track batches by expiration date with location-based inventory
- **Usage Analytics** - Historical consumption patterns for demand prediction and optimization
- **Computer Vision** - On-device cart verification with anomaly detection (in development)
- **Accessibility-First** - Full VoiceOver support, haptic feedback, Dynamic Type, and large touch targets

## Architecture

Built with **SwiftUI** following MVVM pattern:

### Core Models
- `ProductBatch` - Batch/lot tracking with FEFO scoring
- `CartManifest` - Flight cart requirements with client specifications
- `ReturnedCart` & `WasteRecord` - Return processing and waste tracking
- `ProductUsageHistory` - Historical analytics for demand prediction

### Views
- `WarehouseWorkflowView` - Main tablet interface with workflow selector
- `CartPreparationWorkflow` - FEFO-guided cart loading
- `ReturnProcessingWorkflow` - Aircraft return handling
- `InventoryCheckWorkflow` - Stock verification
- `WasteRecordingWorkflow` - Waste documentation

### Services
- `AccessibilityManager` - VoiceOver announcements and accessibility features
- `HapticManager` - Haptic feedback for all user interactions
- `DataService` - Shared data management (in development)

## Technology Stack

**Current (MVP):**
- SwiftUI - Native iOS interface
- Foundation - Core data models
- Accessibility APIs - VoiceOver, haptics, Dynamic Type
- AVFoundation - Camera interface (placeholder)

**Planned:**
- MLX - On-device machine learning for product detection
- Vision Framework - Image analysis and object detection
- Core Data - Local persistence
- CloudKit - Optional data sync

## Building & Running

### Requirements
- Xcode 15.0+
- iOS 17.0+ / iPadOS 17.0+
- macOS Sonoma 14.0+

### Build Instructions

```bash
# Clone the repository
git clone https://github.com/yourusername/Opsight.git
cd Opsight

# Open in Xcode
open Opsight.xcodeproj

# Build from command line
xcodebuild -scheme Opsight -configuration Debug build

# Run on simulator
xcodebuild -scheme Opsight -destination 'platform=iOS Simulator,name=iPad Pro (12.9-inch) (6th generation)' test
```

### Running in Xcode
1. Open `Opsight.xcodeproj`
2. Select a simulator or connected device (iPad recommended for optimal experience)
3. Press `Cmd+R` to build and run

## Development Status

### Current Phase: MVP Development
- Core UI/UX for warehouse workflows
- FEFO batch management and recommendations
- Sample data for demonstrations
- Accessibility features (VoiceOver, haptics)
- Camera interface (placeholder)

### Next Phase: ML Integration
- AVFoundation camera capture
- MLX integration for on-device inference
- Product classification and counting
- Expiration date OCR
- Fill level detection (50% rule)
- Real-time detection overlay

## Key Business Logic

### FEFO (First Expire First Out)
1. Sort batches by expiration date (earliest first)
2. Apply 5-day expiration margin (flag critical batches)
3. Assign batches to cart manifests with visual indicators
4. Block expired batches, alert on critical batches

### Return Processing (50% Rule)
1. Scan returned cart items from aircraft
2. Opened items >50% full → restock
3. Opened items ≤50% full → dispose as waste
4. Check expiration dates (expired → waste)
5. Update inventory for restocked items

### Usage Analytics
- Track actual consumption vs. expected quantity
- Calculate utilization rates by route/product
- Identify high performers (>80% utilization) for stock increase
- Flag low performers (<30% utilization) for reduction

## Accessibility

Opsight is designed with accessibility as a core requirement:

- **VoiceOver Support** - Full screen reader compatibility with descriptive labels
- **Haptic Feedback** - Success, error, warning, and selection haptics
- **Dynamic Type** - Text scales with user preferences
- **Large Touch Targets** - Minimum 44x44pt for all interactive elements
- **High Contrast** - WCAG AA compliant color ratios
- **Icon-First Design** - Universal understanding across languages

## Documentation

- **`CLAUDE.md`** - Development guide and architecture reference
- **`CONCEPT.md`** - Full product vision, features, and roadmap
- **`CAMERA_SETUP.md`** - Camera integration guide
- **`MLX_MODEL_USAGE.md`** - ML model integration documentation

## Contributing

This project is currently in early development. Contribution guidelines will be added as the project matures.

## License

[License information to be added]

## Contact

For questions or collaboration opportunities, please open an issue on GitHub.

---

**Built for Gategroup airline catering operations | Optimized for iPad | Accessibility-first design**