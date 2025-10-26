//
//  HomeView.swift
//  Opsight
//
//  Created by toño on 25/10/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var accessibilityManager: AccessibilityManager
    @ObservedObject var dataService = DataService.shared

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome card with current user info
                    WelcomeCard()

                    // Quick stats
                    QuickStatsView(dataService: dataService)

                    // Upcoming flights overview
                    UpcomingFlightsOverview(dataService: dataService)

                    // Recent sessions
                    RecentSessionsView(dataService: dataService)

                    // Performance insights
                    PerformanceInsightsView(dataService: dataService)

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Opsight Dashboard")
        }
    }
}

struct WelcomeCard: View {
    var currentShift: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Morning"
        case 12..<17: return "Afternoon"
        case 17..<22: return "Evening"
        default: return "Night"
        }
    }

    var shiftGreeting: String {
        "Good \(currentShift), Warehouse Team"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title)
                    .foregroundColor(.blue)
                Text(shiftGreeting)
                    .font(.title2)
                    .fontWeight(.bold)
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gate Group Catering")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text("Cart Loading Station 3")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(Date(), style: .time)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(Date(), style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            Text("Ready to scan and verify flight carts. Check upcoming flights below.")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.15), Color.blue.opacity(0.05)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(shiftGreeting). Gate Group Catering, Cart Loading Station 3")
    }
}

struct QuickStatsView: View {
    @ObservedObject var dataService: DataService

    var completedToday: Int {
        dataService.totalCartsLoaded()
    }

    var averageAccuracy: Double {
        dataService.averageAccuracy()
    }

    var pendingFlights: Int {
        dataService.availableFlights.count
    }

    var totalItemsToday: Int {
        dataService.todaySessions().reduce(0) { $0 + $1.manifest.totalItems }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Performance")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(
                    title: "Carts Verified",
                    value: "\(completedToday)",
                    icon: "checkmark.seal.fill",
                    color: .green
                )
                StatCard(
                    title: "Avg Accuracy",
                    value: "\(Int(averageAccuracy * 100))%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue
                )
                StatCard(
                    title: "Pending Flights",
                    value: "\(pendingFlights)",
                    icon: "airplane.circle",
                    color: .orange
                )
                StatCard(
                    title: "Items Verified",
                    value: "\(totalItemsToday)",
                    icon: "cube.box.fill",
                    color: .purple
                )
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

struct RecentSessionsView: View {
    @ObservedObject var dataService: DataService

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)

            let sessions = dataService.todaySessions()

            if sessions.isEmpty {
                Text("No activity yet. Start scanning to see your history here!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(sessions.prefix(5)) { session in
                    FlightSessionRow(session: session)
                }
            }
        }
    }
}

struct FlightSessionRow: View {
    let session: LoadingSession

    var timeAgo: String {
        let interval = Date().timeIntervalSince(session.scannedAt)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return "\(hours)h ago"
        } else if minutes > 0 {
            return "\(minutes)m ago"
        } else {
            return "Just now"
        }
    }

    var body: some View {
        HStack {
            Image(systemName: "airplane.circle.fill")
                .font(.system(size: 32))
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text("Flight \(session.manifest.flightNumber)")
                    .font(.headline)
                HStack(spacing: 4) {
                    Text(session.manifest.destination)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(timeAgo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(session.accuracy * 100))%")
                    .font(.headline)
                    .foregroundColor(session.accuracy >= 0.95 ? .green : .orange)
                HStack(spacing: 4) {
                    if !session.missingItems.isEmpty {
                        Label("\(session.missingItems.reduce(0) { $0 + $1.quantity })", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                    if session.accuracy >= 0.95 {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Flight \(session.manifest.flightNumber) to \(session.manifest.destination), scanned \(timeAgo), accuracy \(Int(session.accuracy * 100)) percent")
    }
}

// MARK: - New Views

struct UpcomingFlightsOverview: View {
    @ObservedObject var dataService: DataService

    var urgentFlights: [CartManifest] {
        dataService.availableFlights.filter { $0.isUrgent }.sorted { $0.departureTime < $1.departureTime }
    }

    var nextThreeFlights: [CartManifest] {
        Array(dataService.availableFlights.sorted { $0.departureTime < $1.departureTime }.prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Upcoming Flights")
                    .font(.headline)
                Spacer()
                if !urgentFlights.isEmpty {
                    Label("\(urgentFlights.count) urgent", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(6)
                }
            }

            if nextThreeFlights.isEmpty {
                Text("No upcoming flights scheduled")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(nextThreeFlights) { flight in
                    UpcomingFlightCard(flight: flight)
                }
            }
        }
        .accessibilityElement(children: .contain)
    }
}

struct UpcomingFlightCard: View {
    let flight: CartManifest

    var timeUntilDeparture: String {
        let interval = flight.departureTime.timeIntervalSinceNow
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return "Departs in \(hours)h \(minutes)m"
        } else {
            return "Departs in \(minutes)m"
        }
    }

    var departureTimeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: flight.departureTime)
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(flight.flightNumber)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(flight.destination)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    if flight.isUrgent {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                }

                HStack(spacing: 8) {
                    Label(departureTimeFormatted, systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("•")
                        .foregroundColor(.secondary)

                    Text("\(flight.totalItems) items")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let aircraft = flight.aircraftType {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(aircraft)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(timeUntilDeparture)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(flight.isUrgent ? .orange : .blue)
            }
        }
        .padding()
        .background(flight.isUrgent ? Color.orange.opacity(0.05) : Color.gray.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(flight.isUrgent ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Flight \(flight.flightNumber) to \(flight.destination), \(timeUntilDeparture), \(flight.totalItems) items")
    }
}

struct PerformanceInsightsView: View {
    @ObservedObject var dataService: DataService

    var perfectScores: Int {
        dataService.todaySessions().filter { $0.accuracy >= 0.95 }.count
    }

    var totalSessions: Int {
        dataService.todaySessions().count
    }

    var perfectScorePercentage: Int {
        guard totalSessions > 0 else { return 0 }
        return Int((Double(perfectScores) / Double(totalSessions)) * 100)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Insights")
                .font(.headline)

            if totalSessions == 0 {
                Text("Complete your first cart scan to see insights")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                VStack(spacing: 12) {
                    InsightCard(
                        icon: "star.fill",
                        title: "Perfect Scans",
                        value: "\(perfectScores) of \(totalSessions)",
                        subtitle: "\(perfectScorePercentage)% accuracy rate",
                        color: .green
                    )

                    if dataService.averageAccuracy() >= 0.95 {
                        InsightCard(
                            icon: "trophy.fill",
                            title: "Excellent Work!",
                            value: "Above Target",
                            subtitle: "Maintaining 95%+ average accuracy",
                            color: .yellow
                        )
                    }

                    if dataService.availableFlights.contains(where: { $0.isUrgent }) {
                        InsightCard(
                            icon: "clock.badge.exclamationmark.fill",
                            title: "Urgent Attention",
                            value: "\(dataService.availableFlights.filter { $0.isUrgent }.count) flights",
                            subtitle: "Departing within 2 hours",
                            color: .orange
                        )
                    }
                }
            }
        }
    }
}

struct InsightCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value). \(subtitle)")
    }
}

