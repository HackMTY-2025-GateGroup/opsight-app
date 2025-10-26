//
//  FlightSelectionView.swift
//  Opsight
//
//  Created by Claude on 25/10/25.
//

import SwiftUI

struct FlightSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var accessibilityManager: AccessibilityManager
    @ObservedObject var dataService = DataService.shared

    @State private var selectedFlight: CartManifest?
    @State private var showCamera = false
    @StateObject private var cameraPermission = CameraPermissionManager.shared

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if dataService.availableFlights.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)

                        Text("All Flights Loaded!")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Great job! You've completed all cart loading for today.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button(action: {
                            dismiss()
                        }) {
                            Text("Return Home")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Header
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Select Flight")
                                    .font(.title2)
                                    .fontWeight(.bold)

                                Text("\(dataService.availableFlights.count) flights ready for cart loading")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()

                            // Flight list
                            ForEach(dataService.availableFlights) { flight in
                                FlightCard(
                                    flight: flight,
                                    isSelected: selectedFlight?.id == flight.id,
                                    onSelect: {
                                        HapticManager.shared.selection()
                                        selectedFlight = flight
                                    }
                                )
                                .padding(.horizontal)
                            }
                        }
                        .padding(.bottom, 100)
                    }

                    // Bottom action button
                    VStack {
                        Divider()

                        Button(action: {
                            guard let flight = selectedFlight else { return }
                            HapticManager.shared.impact()
                            dataService.selectFlight(flight)
                            accessibilityManager.announceForAccesibility("Flight \(flight.flightNumber) selected. Starting AR scan.")
                            showCamera = true
                        }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Start Scanning")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedFlight != nil ? Color.blue : Color.gray)
                            .cornerRadius(12)
                        }
                        .disabled(selectedFlight == nil)
                        .padding()
                        .accessibilityLabel(selectedFlight != nil ? "Start scanning for flight \(selectedFlight!.flightNumber)" : "Select a flight first")
                    }
                    .background(Color(.systemBackground))
                }
            }
            .navigationTitle("Cart Loading")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        HapticManager.shared.impact()
                        dismiss()
                    }
                    .accessibilityLabel("Cancel flight selection")
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            if let flight = selectedFlight {
                ARTrolleyView(manifest: flight)
                    .environmentObject(accessibilityManager)
            }
        }
    }
}

struct FlightCard: View {
    let flight: CartManifest
    let isSelected: Bool
    let onSelect: () -> Void

    private var timeUntilDeparture: String {
        let interval = flight.departureTime.timeIntervalSinceNow
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private var departureTimeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: flight.departureTime)
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 0) {
                // Header with flight info
                HStack(spacing: 12) {
                    // Flight icon
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 50, height: 50)

                        Image(systemName: "airplane")
                            .font(.system(size: 22))
                            .foregroundColor(.blue)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(flight.flightNumber)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(flight.destination)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }

                        HStack(spacing: 12) {
                            Label(departureTimeFormatted, systemImage: "clock")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Label(timeUntilDeparture, systemImage: "timer")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }

                    Spacer()

                    // Selection indicator
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.blue)
                    } else {
                        Image(systemName: "circle")
                            .font(.system(size: 28))
                            .foregroundColor(.gray.opacity(0.3))
                    }
                }
                .padding()

                Divider()
                    .padding(.horizontal)

                // Cart details
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("\(flight.totalPassengers)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Passengers")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Divider()
                        .frame(height: 30)

                    VStack(spacing: 4) {
                        Text("\(flight.totalItems)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Items")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Divider()
                        .frame(height: 30)

                    VStack(spacing: 4) {
                        Text("\(flight.expectedItems.count)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Categories")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding()
            }
            .background(isSelected ? Color.blue.opacity(0.05) : Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? Color.blue.opacity(0.2) : Color.clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Flight \(flight.flightNumber) to \(flight.destination). Departure at \(departureTimeFormatted), in \(timeUntilDeparture). \(flight.totalPassengers) passengers, \(flight.totalItems) items.")
        .accessibilityHint(isSelected ? "Selected. Double tap to deselect." : "Double tap to select this flight.")
    }
}

#Preview {
    FlightSelectionView()
        .environmentObject(AccessibilityManager())
}
