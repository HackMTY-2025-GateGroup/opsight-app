//
//  ScanResultsView.swift
//  Opsight
//
//  Created by Claude on 25/10/25.
//

import SwiftUI

struct ScanResultsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var accessibilityManager: AccessibilityManager
    @ObservedObject var dataService = DataService.shared

    let manifest: CartManifest
    let session: LoadingSession

    @State private var showDetails = false
    @State private var animateAccuracy = false

    var accuracyColor: Color {
        if session.accuracy >= 0.95 {
            return .green
        } else if session.accuracy >= 0.85 {
            return .orange
        } else {
            return .red
        }
    }

    var accuracyIcon: String {
        if session.accuracy >= 0.95 {
            return "checkmark.circle.fill"
        } else if session.accuracy >= 0.85 {
            return "exclamationmark.triangle.fill"
        } else {
            return "xmark.circle.fill"
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with accuracy
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .stroke(accuracyColor.opacity(0.2), lineWidth: 12)
                                .frame(width: 160, height: 160)

                            Circle()
                                .trim(from: 0, to: animateAccuracy ? session.accuracy : 0)
                                .stroke(
                                    accuracyColor,
                                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                                )
                                .frame(width: 160, height: 160)
                                .rotationEffect(.degrees(-90))
                                .animation(.spring(response: 1.0, dampingFraction: 0.7), value: animateAccuracy)

                            VStack(spacing: 4) {
                                Image(systemName: accuracyIcon)
                                    .font(.system(size: 40))
                                    .foregroundColor(accuracyColor)

                                Text("\(Int(session.accuracy * 100))%")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(accuracyColor)

                                Text("Accuracy")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 20)

                        Text(session.accuracy >= 0.95 ? "Great job!" : "Review discrepancies")
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text("Flight \(manifest.flightNumber) to \(manifest.destination)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Scan complete. Accuracy \(Int(session.accuracy * 100)) percent for flight \(manifest.flightNumber) to \(manifest.destination)")

                    Divider()
                        .padding(.horizontal)

                    // Summary cards
                    VStack(spacing: 16) {
                        ResultSummaryCard(
                            title: "Expected Items",
                            value: "\(manifest.totalItems)",
                            icon: "list.bullet.clipboard",
                            color: .blue
                        )

                        if !session.missingItems.isEmpty {
                            ResultSummaryCard(
                                title: "Missing Items",
                                value: "\(session.missingItems.reduce(0) { $0 + $1.quantity })",
                                icon: "exclamationmark.triangle.fill",
                                color: .orange
                            )
                        }

                        if !session.extraItems.isEmpty {
                            ResultSummaryCard(
                                title: "Extra Items",
                                value: "\(session.extraItems.reduce(0) { $0 + $1.quantity })",
                                icon: "plus.circle.fill",
                                color: .red
                            )
                        }
                    }
                    .padding(.horizontal)

                    // Detailed breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        Button(action: {
                            withAnimation {
                                showDetails.toggle()
                            }
                            HapticManager.shared.selection()
                        }) {
                            HStack {
                                Text("Item Details")
                                    .font(.headline)
                                Spacer()
                                Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                                    .foregroundColor(.blue)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel(showDetails ? "Hide item details" : "Show item details")

                        if showDetails {
                            VStack(spacing: 12) {
                                ForEach(manifest.expectedItems) { expectedItem in
                                    ItemComparisonRow(
                                        expectedItem: expectedItem,
                                        detectedQuantity: session.detectedItems.first(where: { $0.name == expectedItem.name })?.quantity ?? 0
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Action buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            HapticManager.shared.success()
                            accessibilityManager.announceForAccesibility("Cart approved")
                            dataService.completeSession(session)
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text(session.accuracy >= 0.95 ? "Approve & Continue" : "Approve Despite Issues")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(session.accuracy >= 0.95 ? Color.green : Color.orange)
                            .cornerRadius(12)
                        }
                        .accessibilityLabel(session.accuracy >= 0.95 ? "Approve cart and continue" : "Approve cart despite discrepancies")

                        Button(action: {
                            HapticManager.shared.impact()
                            accessibilityManager.announceForAccesibility("Rescanning cart")
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Rescan Cart")
                            }
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .accessibilityLabel("Rescan the cart")
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Scan Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        HapticManager.shared.impact()
                        dismiss()
                    }
                    .accessibilityLabel("Close results")
                }
            }
        }
        .onAppear {
            // Trigger haptic feedback based on results
            if session.accuracy >= 0.95 {
                HapticManager.shared.success()
            } else if session.accuracy >= 0.85 {
                HapticManager.shared.warning()
            } else {
                HapticManager.shared.error()
            }

            // Announce results
            let missingCount = session.missingItems.reduce(0) { $0 + $1.quantity }
            let extraCount = session.extraItems.reduce(0) { $0 + $1.quantity }

            var announcement = "Scan complete. Accuracy \(Int(session.accuracy * 100)) percent."
            if missingCount > 0 {
                announcement += " \(missingCount) items missing."
            }
            if extraCount > 0 {
                announcement += " \(extraCount) extra items found."
            }

            accessibilityManager.announceForAccesibility(announcement)

            // Animate accuracy circle
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animateAccuracy = true
            }
        }
    }
}

// MARK: - Supporting Views

struct ResultSummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
            }

            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

struct ItemComparisonRow: View {
    let expectedItem: MealItem
    let detectedQuantity: Int

    var status: ItemStatus {
        if detectedQuantity == expectedItem.quantity {
            return .correct
        } else if detectedQuantity < expectedItem.quantity {
            return .missing
        } else {
            return .extra
        }
    }

    var statusIcon: String {
        switch status {
        case .correct: return "checkmark.circle.fill"
        case .missing: return "exclamationmark.triangle.fill"
        case .extra: return "plus.circle.fill"
        }
    }

    var statusColor: Color {
        switch status {
        case .correct: return .green
        case .missing: return .orange
        case .extra: return .red
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: expectedItem.category.icon)
                .font(.system(size: 20))
                .foregroundColor(expectedItem.category.color)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(expectedItem.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    Text("Expected: \(expectedItem.quantity)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("•")
                        .foregroundColor(.secondary)
                    Text("Detected: \(detectedQuantity)")
                        .font(.caption)
                        .foregroundColor(statusColor)
                        .fontWeight(.semibold)
                }
            }

            Spacer()

            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .font(.system(size: 20))
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(status != .correct ? statusColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(expectedItem.name). Expected \(expectedItem.quantity), detected \(detectedQuantity). Status: \(status.rawValue)")
    }

    enum ItemStatus: String {
        case correct = "Correct"
        case missing = "Missing items"
        case extra = "Extra items"
    }
}

#Preview {
    let manifest = CartManifest(
        flightNumber: "AA123",
        destination: "LAX",
        departureTime: Date(),
        totalPassengers: 150,
        expectedItems: [
            MealItem(name: "Chicken Meal", category: .lunch, quantity: 45),
            MealItem(name: "Vegetarian Meal", category: .lunch, quantity: 15),
            MealItem(name: "Beverages", category: .beverage, quantity: 60),
            MealItem(name: "Snacks", category: .snack, quantity: 30)
        ]
    )

    let detectedItems = [
        MealItem(name: "Chicken Meal", category: .lunch, quantity: 45),
        MealItem(name: "Vegetarian Meal", category: .lunch, quantity: 15),
        MealItem(name: "Beverages", category: .beverage, quantity: 58),
        MealItem(name: "Snacks", category: .snack, quantity: 35)
    ]

    let session = LoadingSession(
        manifest: manifest,
        detectedItems: detectedItems,
        status: .completed
    )

    ScanResultsView(manifest: manifest, session: session)
        .environmentObject(AccessibilityManager())
}
