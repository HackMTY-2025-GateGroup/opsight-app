//
//  PreScanInstructionsView.swift
//  Opsight
//
//  Created for pre-camera scanning instructions
//

import SwiftUI

/// Full-screen instructions shown BEFORE opening the camera
/// Explains how to use AR trolley guide for accurate scanning
struct PreScanInstructionsView: View {
    let manifest: CartManifest
    @EnvironmentObject var accessibilityManager: AccessibilityManager
    @Environment(\.dismiss) private var dismiss
    let onContinue: () -> Void

    @State private var currentPage = 0
    private let totalPages = 3

    var body: some View {
        ZStack {
            // System background
            Color(.systemBackground)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        HapticManager.shared.impact()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Cancel scanning")

                    Spacer()
                }
                .padding()

                // Content
                TabView(selection: $currentPage) {
                    // Page 1: Introduction
                    InstructionPage(
                        icon: "camera.viewfinder",
                        title: "Scan Cart with AR",
                        subtitle: "Flight \(manifest.flightNumber) → \(manifest.destination)",
                        description: "Place a virtual trolley guide over the real cart, then capture a photo when aligned.",
                        items: [
                            "Virtual gray guide will appear",
                            "Align real cart inside guide",
                            "Guide turns green when ready"
                        ],
                        pageNumber: 1,
                        totalPages: totalPages
                    )
                    .tag(0)

                    // Page 2: Positioning
                    InstructionPage(
                        icon: "figure.stand",
                        title: "Stand 1.5m Away",
                        subtitle: "About 5 feet from cart",
                        description: "Position yourself in front of the cart at chest height for best results.",
                        items: [
                            "Stand 1.5 meters (5 feet) back",
                            "Hold device at chest level",
                            "Point straight at cart center",
                            "Keep device steady"
                        ],
                        pageNumber: 2,
                        totalPages: totalPages
                    )
                    .tag(1)

                    // Page 3: Alignment
                    InstructionPage(
                        icon: "checkmark.circle",
                        title: "Align and Capture",
                        subtitle: "Match cart to guide",
                        description: "Move until the real cart fits inside the gray guide. It will turn green when perfectly aligned.",
                        items: [
                            "Gray = keep adjusting",
                            "Green = ready to capture!",
                            "Tap screen to place guide",
                            "Tap button to capture photo"
                        ],
                        pageNumber: 3,
                        totalPages: totalPages
                    )
                    .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 20)

                // Action buttons
                HStack(spacing: 16) {
                    if currentPage > 0 {
                        Button(action: {
                            HapticManager.shared.selection()
                            withAnimation {
                                currentPage -= 1
                            }
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                        }
                        .accessibilityLabel("Go to previous page")
                    }

                    if currentPage < totalPages - 1 {
                        Button(action: {
                            HapticManager.shared.selection()
                            withAnimation {
                                currentPage += 1
                            }
                        }) {
                            HStack {
                                Text("Next")
                                Image(systemName: "chevron.right")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        .accessibilityLabel("Go to next page")
                    } else {
                        Button(action: {
                            HapticManager.shared.impact()
                            accessibilityManager.announceForAccesibility("Starting AR camera")
                            onContinue()
                        }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .font(.title3)
                                Text("Start Scanning")
                            }
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        .accessibilityLabel("Start AR camera scanning")
                        .accessibilityHint("Opens camera with AR trolley guide overlay")
                    }
                }
                .padding()
            }
        }
        .onAppear {
            announceInstructions()
        }
    }

    private func announceInstructions() {
        let announcement = """
        AR-Guided Cart Scanning for flight \(manifest.flightNumber).
        Swipe to navigate through 3 pages of instructions.
        Page 1 of 3: Introduction to AR scanning.
        """
        accessibilityManager.announceForAccesibility(announcement)
    }
}

// MARK: - Instruction Page

struct InstructionPage: View {
    let icon: String
    let title: String
    let subtitle: String
    let description: String
    let items: [String]
    let pageNumber: Int
    let totalPages: Int

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: icon)
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
            }

            // Title and subtitle
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Description
            Text(description)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            // Instruction items
            VStack(alignment: .leading, spacing: 12) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)

                        Text(item)
                            .font(.body)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 30)
            .padding(.top, 10)

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle). Page \(pageNumber) of \(totalPages). \(description)")
    }
}

// MARK: - Preview

#Preview {
    PreScanInstructionsView(
        manifest: CartManifest(
            flightNumber: "AA123",
            destination: "LAX",
            departureTime: Date(),
            totalPassengers: 150,
            expectedItems: [
                MealItem(name: "Chicken Meal", category: .lunch, quantity: 45)
            ]
        ),
        onContinue: {}
    )
    .environmentObject(AccessibilityManager())
}
