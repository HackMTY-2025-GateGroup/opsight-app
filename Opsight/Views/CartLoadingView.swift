//
//  CartLoadingView.swift
//  Opsight
//
//  Created by toño on 25/10/25.
//

import SwiftUI

struct CartLoadingView: View {
    @EnvironmentObject var accessibilityManager: AccessibilityManager
    @ObservedObject var dataService = DataService.shared

    @State private var showFlightSelection = false

    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Spacer()

                // Header
                VStack(spacing: 12) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 70))
                        .foregroundColor(.blue)

                    Text("Cart Scanner")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Scan flight carts to verify contents")
                        .font(.body)
                        .foregroundColor(.secondary)
                }

                // Flight cart button
                VStack(spacing: 20) {
                    ScanModeCard(
                        icon: "airplane",
                        title: "Flight Carts",
                        subtitle: "\(dataService.availableFlights.count) flights ready",
                        color: .blue,
                        action: {
                            HapticManager.shared.impact()
                            showFlightSelection = true
                        }
                    )
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .navigationTitle("Cart Scanning")
            .sheet(isPresented: $showFlightSelection) {
                FlightSelectionView()
                    .environmentObject(accessibilityManager)
            }
        }
    }
}

struct ScanModeCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 60, height: 60)

                    Image(systemName: icon)
                        .font(.system(size: 28))
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(title). \(subtitle)")
        .accessibilityHint("Double tap to select this mode")
    }
}

#Preview {
    CartLoadingView()
        .environmentObject(AccessibilityManager())
}
