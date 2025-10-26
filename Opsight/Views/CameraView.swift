//
//  CameraView.swift
//  Opsight
//
//  Created by toño on 25/10/25.
//

import SwiftUI

struct CameraView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var accessibilityManager: AccessibilityManager

    let manifest: CartManifest

    @State private var isScanning = false
    @State private var scanProgress: CGFloat = 0
    @State private var detectedItems: [DetectedItem] = []
    @State private var showResults = false
    @State private var scanComplete = false

    var body: some View {
        ZStack {
            // Mock camera background (gradient to simulate camera view)
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.gray.opacity(0.3),
                    Color.gray.opacity(0.5),
                    Color.gray.opacity(0.3)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)

            // Mock cart image placeholder
            VStack {
                Spacer()
                Image(systemName: "cart.fill")
                    .font(.system(size: 120))
                    .foregroundColor(.white.opacity(0.2))
                Spacer()
            }

            // Scanning overlay
            if isScanning {
                ScanningOverlay(progress: scanProgress, detectedItems: detectedItems)
            }

            // Top bar
            VStack {
                HStack {
                    Button(action: {
                        HapticManager.shared.impact()
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                            Text("Cancel")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(20)
                    }
                    .accessibilityLabel("Cancel scanning")

                    Spacer()

                    // Flight info badge
                    HStack(spacing: 8) {
                        Image(systemName: "airplane")
                        Text(manifest.flightNumber)
                        Image(systemName: "arrow.right")
                        Text(manifest.destination)
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(20)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Flight \(manifest.flightNumber) to \(manifest.destination)")
                }
                .padding()

                Spacer()
            }

            // Bottom controls
            VStack {
                Spacer()

                if !isScanning && !scanComplete {
                    VStack(spacing: 16) {
                        Text("Position cart in frame")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(12)

                        Button(action: startScanning) {
                            ZStack {
                                Circle()
                                    .stroke(Color.white, lineWidth: 5)
                                    .frame(width: 80, height: 80)

                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 65, height: 65)

                                Image(systemName: "camera.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                            }
                        }
                        .accessibilityLabel("Start scanning cart")
                        .accessibilityHint("Begins AI-powered cart verification")
                    }
                    .padding(.bottom, 50)
                } else if isScanning {
                    VStack(spacing: 12) {
                        Text("Scanning...")
                            .font(.headline)
                            .foregroundColor(.white)

                        ProgressView(value: scanProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .cyan))
                            .frame(width: 200)

                        Text("\(Int(scanProgress * 100))% Complete")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(16)
                    .padding(.bottom, 50)
                }
            }
        }
        .sheet(isPresented: $showResults) {
            ScanResultsView(manifest: manifest, session: createMockSession())
        }
    }

    private func startScanning() {
        HapticManager.shared.impact()
        accessibilityManager.announceForAccesibility("Starting cart scan")

        isScanning = true
        scanProgress = 0
        detectedItems = []

        // Simulate scanning progress
        let totalDuration: Double = 3.0
        let steps = 30
        let stepDuration = totalDuration / Double(steps)

        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                scanProgress = CGFloat(i) / CGFloat(steps)

                // Simulate item detection at intervals
                if i % 8 == 0 && i > 0 {
                    addRandomDetectedItem()
                }

                // Haptic feedback at milestones
                if i == steps / 3 || i == (2 * steps) / 3 {
                    HapticManager.shared.selection()
                }

                // Complete scan
                if i == steps {
                    completeScan()
                }
            }
        }
    }

    private func addRandomDetectedItem() {
        let items = manifest.expectedItems
        if let randomItem = items.randomElement() {
            let detected = DetectedItem(
                name: randomItem.name,
                confidence: Double.random(in: 0.85...0.98),
                position: CGPoint(
                    x: CGFloat.random(in: 0.2...0.8),
                    y: CGFloat.random(in: 0.3...0.7)
                )
            )
            detectedItems.append(detected)
            HapticManager.shared.selection()
        }
    }

    private func completeScan() {
        scanComplete = true
        HapticManager.shared.success()
        accessibilityManager.announceForAccesibility("Scan complete. Showing results.")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showResults = true
            isScanning = false
        }
    }

    private func createMockSession() -> LoadingSession {
        // Create mock detected items with slight variations
        let detectedItems = [
            MealItem(name: "Chicken Meal", category: .lunch, quantity: 45),
            MealItem(name: "Vegetarian Meal", category: .lunch, quantity: 15),
            MealItem(name: "Beverages", category: .beverage, quantity: 58), // 2 missing
            MealItem(name: "Snacks", category: .snack, quantity: 35) // 5 extra
        ]

        return LoadingSession(
            manifest: manifest,
            detectedItems: detectedItems,
            status: .completed
        )
    }
}

// MARK: - Supporting Views

struct ScanningOverlay: View {
    let progress: CGFloat
    let detectedItems: [DetectedItem]

    @State private var scanLinePosition: CGFloat = 0

    var body: some View {
        ZStack {
            // Corner brackets (viewfinder style)
            GeometryReader { geometry in
                let size = geometry.size
                let bracketSize: CGFloat = 60

                // Top-left
                Path { path in
                    path.move(to: CGPoint(x: 40, y: 40 + bracketSize))
                    path.addLine(to: CGPoint(x: 40, y: 40))
                    path.addLine(to: CGPoint(x: 40 + bracketSize, y: 40))
                }
                .stroke(Color.cyan, lineWidth: 4)

                // Top-right
                Path { path in
                    path.move(to: CGPoint(x: size.width - 40 - bracketSize, y: 40))
                    path.addLine(to: CGPoint(x: size.width - 40, y: 40))
                    path.addLine(to: CGPoint(x: size.width - 40, y: 40 + bracketSize))
                }
                .stroke(Color.cyan, lineWidth: 4)

                // Bottom-left
                Path { path in
                    path.move(to: CGPoint(x: 40, y: size.height - 40 - bracketSize))
                    path.addLine(to: CGPoint(x: 40, y: size.height - 40))
                    path.addLine(to: CGPoint(x: 40 + bracketSize, y: size.height - 40))
                }
                .stroke(Color.cyan, lineWidth: 4)

                // Bottom-right
                Path { path in
                    path.move(to: CGPoint(x: size.width - 40 - bracketSize, y: size.height - 40))
                    path.addLine(to: CGPoint(x: size.width - 40, y: size.height - 40))
                    path.addLine(to: CGPoint(x: size.width - 40, y: size.height - 40 - bracketSize))
                }
                .stroke(Color.cyan, lineWidth: 4)

                // Scanning line
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Color.cyan.opacity(0.8), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 2)
                    .offset(y: scanLinePosition)
                    .onAppear {
                        withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
                            scanLinePosition = size.height
                        }
                    }

                // Detection boxes
                ForEach(detectedItems.indices, id: \.self) { index in
                    let item = detectedItems[index]
                    DetectionBox(item: item)
                        .position(
                            x: item.position.x * size.width,
                            y: item.position.y * size.height
                        )
                }
            }
        }
    }
}

struct DetectionBox: View {
    let item: DetectedItem
    @State private var scale: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.name)
                .font(.caption)
                .fontWeight(.semibold)
            Text("\(Int(item.confidence * 100))% confident")
                .font(.caption2)
        }
        .padding(8)
        .background(Color.green.opacity(0.8))
        .foregroundColor(.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.green, lineWidth: 2)
        )
        .scaleEffect(scale)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 1
            }
        }
    }
}

struct DetectedItem: Identifiable {
    let id = UUID()
    let name: String
    let confidence: Double
    let position: CGPoint
}
