# Camera Setup for Opsight

## ⚠️ IMPORTANT: Add Camera Permissions to Info.plist

To fix the black camera screen, you MUST add camera permission keys to your project's Info.plist.

### Step 1: Open Info.plist in Xcode

1. Open `Opsight.xcodeproj` in Xcode
2. In the Project Navigator (left sidebar), find and select the `Info.plist` file
   - If you don't see Info.plist, select your app target → Info tab

### Step 2: Add Required Privacy Keys

Add these two keys to your Info.plist:

#### Method A: Using the Info tab (Easier)
1. Click the **Info** tab in your target settings
2. Under **Custom iOS Target Properties**, click the **+** button
3. Add both keys below:

**Key 1: Camera Usage**
- **Key**: `Privacy - Camera Usage Description`
- **Type**: String
- **Value**: `Opsight needs camera access to scan airline trolley carts using AR technology.`

**Key 2: AR Kit Usage (Required for AR)**
- **Key**: `Privacy - AR Kit Usage Description`
- **Type**: String
- **Value**: `Opsight uses AR to overlay a virtual trolley guide for accurate cart scanning.`

#### Method B: Editing Info.plist directly (Advanced)
If editing the plist file directly, add:

```xml
<key>NSCameraUsageDescription</key>
<string>Opsight needs camera access to scan airline trolley carts using AR technology.</string>
<key>NSARKitUsageDescription</key>
<string>Opsight uses AR to overlay a virtual trolley guide for accurate cart scanning.</string>
```

### Step 3: Rebuild and Run

1. Clean build folder: **Product → Clean Build Folder** (Cmd + Shift + K)
2. Build and run the app
3. When you tap "Start Scanning", you'll see the permission request dialog
4. Grant camera permission

---

## ✅ What's Been Fixed

### 1. **Camera Black Screen** → Fixed
- Added `CameraPermissionManager` to request permissions
- Added permission check before showing AR camera
- Shows permission request UI if not authorized

### 2. **Instruction Sheet** → Simplified & System Colors
- ✅ Changed from blue gradient to system background
- ✅ Simplified to 3 clear pages
- ✅ Using system colors (.primary, .secondary, .blue)
- ✅ Clearer, more concise instructions

### 3. **Camera View** → Decluttered
- ❌ Removed: PositioningInstructionsView overlay
- ❌ Removed: Progress bar
- ❌ Removed: Detection feedback cards
- ❌ Removed: Manual entry button
- ✅ Kept: Simple status indicator (top)
- ✅ Kept: Capture button (bottom, when cart placed)

### 4. **Trolley Model** → Updated to Match Real Cart
- **Width**: 38cm (single trolley unit)
- **Height**: 100cm (matches image)
- **Depth**: 56cm (standard airline cart)
- **Drawers**: 6 compartments per unit (~16cm each)
- **Color**: Transparent gray (turns green when aligned)

---

## 📱 User Flow (After Setup)

1. **Select Flight** → Shows flight list
2. **Instruction Sheet** → 3-page carousel appears
3. **Tap "Start Scanning"** → Camera permission requested (first time only)
4. **AR Camera Opens** → See live camera feed
5. **Move Device** → Status shows "Move device to find surface"
6. **Tap to Place Guide** → Transparent gray trolley appears
7. **Align Cart** → Move device until cart fits inside guide
8. **Guide Turns Green** → Perfect alignment!
9. **Tap "Capture Photo"** → Photo captured
10. **Results Shown** → Scan complete

---

## 🎨 AR Guide Trolley Features

The transparent gray guide trolley includes:
- ✅ Semi-transparent gray wireframe (40% opacity)
- ✅ 8 corner sphere markers (help visualize 3D boundaries)
- ✅ Horizontal compartment divider lines (shows drawer levels)
- ✅ Color changes: Gray → Green when aligned
- ✅ Matches real trolley dimensions from your image

---

## 🐛 Troubleshooting

### Black Screen Persists?
1. Check Info.plist has both permission keys
2. Delete app from device/simulator
3. Clean build folder
4. Rebuild and reinstall
5. Check device camera works in Camera app

### Permission Dialog Doesn't Appear?
1. Check Info.plist permissions are saved
2. App might have been denied before - go to Settings → Privacy → Camera → Opsight → Enable

### AR Not Starting?
1. Check device supports ARKit (iPhone 6s or newer, iPad 5th gen or newer)
2. Check iOS version (iOS 11.0+ required for AR)

---

## 📝 Files Modified/Created

**Created:**
1. `Services/CameraPermissionManager.swift` - Permission handling
2. `AR/PreScanInstructionsView.swift` - Pre-camera instructions
3. `CAMERA_SETUP.md` - This file

**Modified:**
1. `AR/TrolleyEntity.swift` - Added guide trolley, updated dimensions
2. `AR/ARTrolleyView.swift` - Removed clutter, simplified UI
3. `AR/ARTrolleyViewModel.swift` - Uses guide cart instead of full cart
4. `Views/FlightSelectionView.swift` - Added permission check, instruction sheet
5. `AR/PreScanInstructionsView.swift` - System colors, clearer text

---

## ✨ Next Steps

After adding the Info.plist keys:

1. The camera will work properly
2. Users will see the transparent gray guide trolley
3. AR will overlay perfectly on the real cart
4. Photo capture will work

**Remember**: The black screen was caused by missing camera permissions in Info.plist!
