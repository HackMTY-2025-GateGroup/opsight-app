//
//  PositioningInstructionsView.swift
//  Opsight
//
//  Created for AR positioning guidance
//

import SwiftUI

/// Instructional overlay showing users how to position camera for optimal AR scanning
struct PositioningInstructionsView: View {
    let isCartDetected: Bool
    @Binding var showInstructions: Bool
    @EnvironmentObject var accessibilityManager: AccessibilityManager

    @State private var currentStep: Int = 0
    private let totalSteps = 3

    var body: some View {
        VStack(spacing: 0) {
            if !isCartDetected && showInstructions {
                instructionsCard
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear {
            announceInstructions()
        }
    }

    private var instructionsCard: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.title2)
                    .foregroundColor(.cyan)

                Text("Position Your Camera")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Button(action: {
                    withAnimation {
                        showInstructions = false
                    }
                    HapticManager.shared.selection()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.7))
                }
                .accessibilityLabel("Dismiss instructions")
            }

            Divider()
                .background(Color.white.opacity(0.3))

            // Step-by-step instructions
            VStack(alignment: .leading, spacing: 12) {
                InstructionStep(
                    number: 1,
                    icon: "move.3d",
                    title: "Move device slowly",
                    description: "Scan the floor to detect horizontal surfaces"
                )

                InstructionStep(
                    number: 2,
                    icon: "hand.tap.fill",
                    title: "Tap to place trolley",
                    description: "When surface detected, tap where trolley should appear"
                )

                InstructionStep(
                    number: 3,
                    icon: "viewfinder.circle",
                    title: "Position camera on cart",
                    description: "Point at trolley items for automatic detection"
                )
            }

            // Visual guide
            CartFramingGuide()
                .frame(height: 150)
                .padding(.top, 8)

            // Dismiss button
            Button(action: {
                withAnimation {
                    showInstructions = false
                }
                HapticManager.shared.impact()
                accessibilityManager.announceForAccesibility("Instructions dismissed")
            }) {
                HStack {
                    Text("Got it!")
                        .fontWeight(.semibold)
                    Image(systemName: "checkmark")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.cyan)
                .cornerRadius(12)
            }
            .accessibilityLabel("Dismiss instructions and start scanning")
            .accessibilityHint("Double tap to begin AR scanning")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.cyan.opacity(0.5), lineWidth: 2)
                )
        )
        .padding()
        .shadow(color: Color.cyan.opacity(0.3), radius: 20)
    }

    private func announceInstructions() {
        let announcement = """
        Positioning instructions:
        Step 1: Move device slowly to detect horizontal surfaces.
        Step 2: Tap screen to place virtual trolley when surface is detected.
        Step 3: Position camera on trolley items for scanning.
        """
        accessibilityManager.announceForAccesibility(announcement)
    }
}

// MARK: - Instruction Step

struct InstructionStep: View {
    let number: Int
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Step number badge
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.2))
                    .frame(width: 32, height: 32)

                Text("\(number)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.cyan)
            }

            // Icon
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.cyan)
                .frame(width: 30)

            // Text content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(number): \(title). \(description)")
    }
}

// MARK: - Cart Framing Guide

struct CartFramingGuide: View {
    @State private var pulseAnimation = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background dimming
                Rectangle()
                    .fill(Color.clear)

                // Target frame (matches typical trolley aspect ratio)
                let frameWidth = geometry.size.width * 0.7
                let frameHeight = frameWidth * 1.5 // Trolley is taller than wide

                // Guide box outline
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        Color.cyan,
                        style: StrokeStyle(
                            lineWidth: 3,
                            lineCap: .round,
                            dash: [10, 5]
                        )
                    )
                    .frame(width: frameWidth, height: frameHeight)
                    .scaleEffect(pulseAnimation ? 1.05 : 1.0)
                    .opacity(pulseAnimation ? 0.6 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )

                // Corner markers
                ForEach(0..<4) { index in
                    CornerMarker(position: CornerPosition(rawValue: index) ?? .topLeft)
                        .frame(width: frameWidth, height: frameHeight)
                }

                // Trolley icon placeholder
                VStack(spacing: 8) {
                    Image(systemName: "cart.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.cyan.opacity(0.4))

                    Text("Align trolley here")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            pulseAnimation = true
        }
        .accessibilityHidden(true) // Visual guide only
    }
}

// MARK: - Corner Marker

enum CornerPosition: Int {
    case topLeft = 0
    case topRight = 1
    case bottomLeft = 2
    case bottomRight = 3
}

struct CornerMarker: View {
    let position: CornerPosition
    private let size: CGFloat = 20

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let offset: CGFloat = 0

                switch position {
                case .topLeft:
                    path.move(to: CGPoint(x: offset + size, y: offset))
                    path.addLine(to: CGPoint(x: offset, y: offset))
                    path.addLine(to: CGPoint(x: offset, y: offset + size))

                case .topRight:
                    path.move(to: CGPoint(x: geometry.size.width - offset - size, y: offset))
                    path.addLine(to: CGPoint(x: geometry.size.width - offset, y: offset))
                    path.addLine(to: CGPoint(x: geometry.size.width - offset, y: offset + size))

                case .bottomLeft:
                    path.move(to: CGPoint(x: offset, y: geometry.size.height - offset - size))
                    path.addLine(to: CGPoint(x: offset, y: geometry.size.height - offset))
                    path.addLine(to: CGPoint(x: offset + size, y: geometry.size.height - offset))

                case .bottomRight:
                    path.move(to: CGPoint(x: geometry.size.width - offset - size, y: geometry.size.height - offset))
                    path.addLine(to: CGPoint(x: geometry.size.width - offset, y: geometry.size.height - offset))
                    path.addLine(to: CGPoint(x: geometry.size.width - offset, y: geometry.size.height - offset - size))
                }
            }
            .stroke(Color.cyan, style: StrokeStyle(lineWidth: 4, lineCap: .round))
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.black.edgesIgnoringSafeArea(.all)

        PositioningInstructionsView(
            isCartDetected: false,
            showInstructions: .constant(true)
        )
        .environmentObject(AccessibilityManager())
    }
}
