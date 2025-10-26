//
//  HistoryView.swift
//  Opsight
//
//  Created by toño on 25/10/25.
//

import SwiftUI

struct HistoryView: View {
    @ObservedObject var dataService = DataService.shared
    @State private var selectedFilter: HistoryFilter = .all

    enum HistoryFilter: String, CaseIterable {
        case all = "All"
        case today = "Today"
        case week = "This Week"
        case perfect = "Perfect Scores"
    }

    var filteredSessions: [LoadingSession] {
        let calendar = Calendar.current
        let now = Date()

        switch selectedFilter {
        case .all:
            return dataService.completedSessions
        case .today:
            return dataService.completedSessions.filter {
                calendar.isDate($0.scannedAt, inSameDayAs: now)
            }
        case .week:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
            return dataService.completedSessions.filter {
                $0.scannedAt >= weekAgo
            }
        case .perfect:
            return dataService.completedSessions.filter {
                $0.accuracy >= 0.95
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if dataService.completedSessions.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("No History Yet")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Your completed scans will appear here")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 0) {
                        // Summary Stats
                        HistorySummaryView(dataService: dataService)
                            .padding()

                        Divider()

                        // Filter Picker
                        Picker("Filter", selection: $selectedFilter) {
                            ForEach(HistoryFilter.allCases, id: \.self) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding()

                        // Sessions List
                        if filteredSessions.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "tray")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("No sessions match this filter")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            List {
                                ForEach(filteredSessions) { session in
                                    NavigationLink(destination: SessionDetailView(session: session)) {
                                        HistorySessionRow(session: session)
                                    }
                                }
                            }
                            .listStyle(PlainListStyle())
                        }
                    }
                }
            }
            .navigationTitle("Loading History")
        }
    }
}

struct SessionDetailView: View {
    let session: LoadingSession

    var scanTimeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: session.scannedAt)
    }

    var departureTimeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: session.manifest.departureTime)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Accuracy Hero Card
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(session.accuracy >= 0.95 ? Color.green.opacity(0.2) : Color.orange.opacity(0.2), lineWidth: 12)
                            .frame(width: 120, height: 120)

                        Circle()
                            .trim(from: 0, to: session.accuracy)
                            .stroke(
                                session.accuracy >= 0.95 ? Color.green : Color.orange,
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 4) {
                            Text("\(Int(session.accuracy * 100))%")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(session.accuracy >= 0.95 ? .green : .orange)
                            Text("Accuracy")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Text(session.accuracy >= 0.95 ? "Excellent Job!" : "Good Work")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("Scanned: \(scanTimeFormatted)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)

                // Flight info
                VStack(alignment: .leading, spacing: 12) {
                    Text("Flight Information")
                        .font(.headline)

                    DetailRow(label: "Flight Number", value: session.manifest.flightNumber)
                    DetailRow(label: "Destination", value: session.manifest.destination)

                    if let aircraft = session.manifest.aircraftType {
                        DetailRow(label: "Aircraft", value: aircraft)
                    }

                    DetailRow(label: "Passengers", value: "\(session.manifest.totalPassengers)")

                    if let extra = session.manifest.extraPassengers, extra > 0 {
                        DetailRow(label: "Extra Passengers", value: "+\(extra)", valueColor: .orange)
                    }

                    DetailRow(label: "Total Items", value: "\(session.manifest.totalItems)")
                    DetailRow(label: "Departure", value: departureTimeFormatted)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)

                // Performance breakdown
                VStack(alignment: .leading, spacing: 12) {
                    Text("Performance Breakdown")
                        .font(.headline)

                    HStack(spacing: 16) {
                        PerformanceMetricCard(
                            title: "Expected",
                            value: "\(session.manifest.totalItems)",
                            icon: "list.bullet.clipboard",
                            color: .blue
                        )

                        if !session.missingItems.isEmpty {
                            PerformanceMetricCard(
                                title: "Missing",
                                value: "\(session.missingItems.reduce(0) { $0 + $1.quantity })",
                                icon: "exclamationmark.triangle",
                                color: .orange
                            )
                        }

                        if !session.extraItems.isEmpty {
                            PerformanceMetricCard(
                                title: "Extra",
                                value: "\(session.extraItems.reduce(0) { $0 + $1.quantity })",
                                icon: "plus.circle",
                                color: .red
                            )
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)

                // Expected Items
                VStack(alignment: .leading, spacing: 12) {
                    Text("Cart Contents")
                        .font(.headline)

                    ForEach(session.manifest.expectedItems) { expectedItem in
                        let detectedQty = session.detectedItems.first(where: { $0.name == expectedItem.name })?.quantity ?? 0
                        DetailedItemRow(
                            item: expectedItem,
                            detectedQuantity: detectedQty
                        )
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)

                // Missing items detail
                if !session.missingItems.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Missing Items", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline)
                            .foregroundColor(.orange)

                        ForEach(session.missingItems) { item in
                            HStack {
                                Image(systemName: item.category.icon)
                                    .foregroundColor(item.category.color)
                                    .frame(width: 24)
                                Text(item.name)
                                    .font(.subheadline)
                                Spacer()
                                Text("Missing: \(item.quantity)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange.opacity(0.2))
                                    .cornerRadius(6)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }

                // Extra items detail
                if !session.extraItems.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Extra Items", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .foregroundColor(.red)

                        ForEach(session.extraItems) { item in
                            HStack {
                                Image(systemName: item.category.icon)
                                    .foregroundColor(item.category.color)
                                    .frame(width: 24)
                                Text(item.name)
                                    .font(.subheadline)
                                Spacer()
                                Text("Extra: \(item.quantity)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red.opacity(0.2))
                                    .cornerRadius(6)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                }

                // Special instructions if any
                if let instructions = session.manifest.specialInstructions {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Special Instructions", systemImage: "info.circle.fill")
                            .font(.headline)
                            .foregroundColor(.blue)
                        Text(instructions)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle("Session Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Supporting Views

struct HistorySummaryView: View {
    @ObservedObject var dataService: DataService

    var totalSessions: Int {
        dataService.completedSessions.count
    }

    var overallAccuracy: Double {
        guard totalSessions > 0 else { return 0 }
        let total = dataService.completedSessions.reduce(0.0) { $0 + $1.accuracy }
        return total / Double(totalSessions)
    }

    var perfectScores: Int {
        dataService.completedSessions.filter { $0.accuracy >= 0.95 }.count
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Overall Performance")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("\(totalSessions)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Total Scans")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 40)

                VStack(spacing: 4) {
                    Text("\(Int(overallAccuracy * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Avg Accuracy")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 40)

                VStack(spacing: 4) {
                    Text("\(perfectScores)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Perfect")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct HistorySessionRow: View {
    let session: LoadingSession

    var timeFormatted: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: session.scannedAt)
    }

    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: session.scannedAt)
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(session.manifest.flightNumber)
                        .font(.headline)
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(session.manifest.destination)
                        .font(.headline)
                }

                HStack(spacing: 4) {
                    Text(dateFormatted)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(timeFormatted)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 8) {
                    Label("\(session.manifest.totalItems) items", systemImage: "cube.box")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    if let aircraft = session.manifest.aircraftType {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(aircraft)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Text("\(Int(session.accuracy * 100))%")
                        .font(.headline)
                        .foregroundColor(session.accuracy >= 0.95 ? .green : .orange)
                    if session.accuracy >= 0.95 {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }

                if !session.missingItems.isEmpty || !session.extraItems.isEmpty {
                    HStack(spacing: 4) {
                        if !session.missingItems.isEmpty {
                            Label("\(session.missingItems.reduce(0) { $0 + $1.quantity })", systemImage: "minus.circle")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                        if !session.extraItems.isEmpty {
                            Label("\(session.extraItems.reduce(0) { $0 + $1.quantity })", systemImage: "plus.circle")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(valueColor)
        }
    }
}

struct DetailedItemRow: View {
    let item: MealItem
    let detectedQuantity: Int

    var status: String {
        if detectedQuantity == item.quantity {
            return "Correct"
        } else if detectedQuantity < item.quantity {
            return "Missing \(item.quantity - detectedQuantity)"
        } else {
            return "Extra \(detectedQuantity - item.quantity)"
        }
    }

    var statusColor: Color {
        if detectedQuantity == item.quantity {
            return .green
        } else if detectedQuantity < item.quantity {
            return .orange
        } else {
            return .red
        }
    }

    var statusIcon: String {
        if detectedQuantity == item.quantity {
            return "checkmark.circle.fill"
        } else if detectedQuantity < item.quantity {
            return "exclamationmark.triangle.fill"
        } else {
            return "plus.circle.fill"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.category.icon)
                .foregroundColor(item.category.color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline)
                HStack(spacing: 4) {
                    Text("Expected: \(item.quantity)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("•")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("Found: \(detectedQuantity)")
                        .font(.caption2)
                        .foregroundColor(statusColor)
                }
            }

            Spacer()

            HStack(spacing: 6) {
                Text(status)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(statusColor)
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
                    .font(.caption)
            }
        }
        .padding(.vertical, 6)
    }
}

struct PerformanceMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

