//
//  SettingsView.swift
//  Opsight
//
//  Created by toño on 25/10/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var accessibilityManager: AccessibilityManager
    @AppStorage("hapticFeedback") private var hapticFeedback = true
    @AppStorage("soundFeedback") private var soundFeedback = true
    @AppStorage("preferredLanguage") private var preferredLanguage = "en"
    @AppStorage("autoConfirmPerfectScans") private var autoConfirmPerfectScans = false
    @AppStorage("showDetailedMetrics") private var showDetailedMetrics = true
    @AppStorage("enableExpirationWarnings") private var enableExpirationWarnings = true
    @AppStorage("warehouseStation") private var warehouseStation = "Station 3"
    @AppStorage("operatorName") private var operatorName = "Warehouse Team"

    var body: some View {
        NavigationView {
            Form {
                // Warehouse Configuration
                Section(header: Text("Warehouse Configuration")) {
                    HStack {
                        Text("Facility")
                        Spacer()
                        Text("Gate Group Catering")
                            .foregroundColor(.secondary)
                    }
                    .accessibilityElement(children: .combine)

                    Picker("Loading Station", selection: $warehouseStation) {
                        Text("Station 1").tag("Station 1")
                        Text("Station 2").tag("Station 2")
                        Text("Station 3").tag("Station 3")
                        Text("Station 4").tag("Station 4")
                        Text("Station 5").tag("Station 5")
                    }
                    .accessibilityHint("Select your current loading station")

                    HStack {
                        Text("Operator")
                        Spacer()
                        Text(operatorName)
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Operator name: \(operatorName)")
                }

                // Cart Scanning Preferences
                Section(header: Text("Scanning Preferences"),
                       footer: Text("Auto-confirm skips the approval screen for perfect scans")) {
                    Toggle("Auto-Confirm Perfect Scans", isOn: $autoConfirmPerfectScans)
                        .accessibilityHint("Automatically approve scans with 100% accuracy")

                    Toggle("Show Detailed Metrics", isOn: $showDetailedMetrics)
                        .accessibilityHint("Display comprehensive scan statistics")

                    Toggle("Expiration Date Warnings", isOn: $enableExpirationWarnings)
                        .accessibilityHint("Alert when items are near expiration")
                }

                // Accessibility
                Section(header: Text("Accessibility"),
                       footer: Text("Haptic and sound feedback help confirm actions without looking at the screen")) {
                    Toggle("Haptic Feedback", isOn: $hapticFeedback)
                        .accessibilityHint("Vibration feedback for actions")

                    Toggle("Sound Feedback", isOn: $soundFeedback)
                        .accessibilityHint("Audio cues for scan results")

                    if accessibilityManager.isVoiceOverRunning {
                        HStack {
                            Label("VoiceOver Active", systemImage: "speaker.wave.2.fill")
                                .foregroundColor(.green)
                            Spacer()
                        }
                        .accessibilityLabel("VoiceOver is currently active")
                    } else {
                        HStack {
                            Label("VoiceOver Inactive", systemImage: "speaker.slash")
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .accessibilityLabel("VoiceOver is currently inactive")
                    }
                }

                // Language
                Section(header: Text("Language & Region")) {
                    Picker("Preferred Language", selection: $preferredLanguage) {
                        Text("English").tag("en")
                        Text("Español").tag("es")
                        Text("Français").tag("fr")
                        Text("Deutsch").tag("de")
                        Text("中文").tag("zh")
                        Text("日本語").tag("ja")
                    }
                    .accessibilityHint("Change the app language")
                }

                // System Information
                Section(header: Text("System Information")) {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text("1.0.0 (Beta)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Build")
                        Spacer()
                        Text("2025.10.001")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Last Sync")
                        Spacer()
                        Text("Just now")
                            .foregroundColor(.green)
                    }
                }

                // Support & Legal
                Section(header: Text("Support & Legal")) {
                    NavigationLink(destination: SupportView()) {
                        Label("Help & Support", systemImage: "questionmark.circle")
                    }

                    NavigationLink(destination: DataManagementView()) {
                        Label("Data Management", systemImage: "externaldrive")
                    }

                    Link(destination: URL(string: "https://gategroup.com/privacy")!) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }

                    Link(destination: URL(string: "https://gategroup.com/terms")!) {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                }

                // Advanced Settings
                Section(header: Text("Advanced")) {
                    NavigationLink(destination: DiagnosticsView()) {
                        Label("Diagnostics", systemImage: "stethoscope")
                    }

                    Button(action: {
                        if hapticFeedback {
                            HapticManager.shared.success()
                        }
                    }) {
                        HStack {
                            Label("Test Haptic Feedback", systemImage: "waveform")
                            Spacer()
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Support Views

struct SupportView: View {
    var body: some View {
        List {
            Section(header: Text("Contact Support")) {
                HStack {
                    Label("Email", systemImage: "envelope")
                    Spacer()
                    Text("support@gategroup.com")
                        .foregroundColor(.blue)
                        .font(.caption)
                }

                HStack {
                    Label("Phone", systemImage: "phone")
                    Spacer()
                    Text("+1-800-GATE-OPS")
                        .foregroundColor(.blue)
                        .font(.caption)
                }

                HStack {
                    Label("Hours", systemImage: "clock")
                    Spacer()
                    Text("24/7")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }

            Section(header: Text("Quick Help")) {
                NavigationLink(destination: Text("How to scan a cart")) {
                    Label("How to Scan a Cart", systemImage: "questionmark.circle")
                }
                NavigationLink(destination: Text("Understanding accuracy scores")) {
                    Label("Understanding Accuracy", systemImage: "chart.bar")
                }
                NavigationLink(destination: Text("Troubleshooting guide")) {
                    Label("Troubleshooting", systemImage: "wrench.and.screwdriver")
                }
                NavigationLink(destination: Text("FEFO best practices")) {
                    Label("FEFO Best Practices", systemImage: "calendar.badge.clock")
                }
            }

            Section(header: Text("Training Resources")) {
                Link(destination: URL(string: "https://training.gategroup.com/cart-loading")!) {
                    Label("Cart Loading Training", systemImage: "play.circle")
                }
                Link(destination: URL(string: "https://training.gategroup.com/safety")!) {
                    Label("Safety Guidelines", systemImage: "exclamationmark.shield")
                }
            }
        }
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DataManagementView: View {
    @ObservedObject var dataService = DataService.shared
    @State private var showingClearDataAlert = false

    var body: some View {
        List {
            Section(header: Text("Storage"),
                   footer: Text("Completed sessions are stored locally on this device")) {
                HStack {
                    Text("Completed Sessions")
                    Spacer()
                    Text("\(dataService.completedSessions.count)")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Available Flights")
                    Spacer()
                    Text("\(dataService.availableFlights.count)")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Storage Used")
                    Spacer()
                    Text("2.4 MB")
                        .foregroundColor(.secondary)
                }
            }

            Section(header: Text("Data Actions")) {
                Button(action: {
                    showingClearDataAlert = true
                }) {
                    Label("Clear All History", systemImage: "trash")
                        .foregroundColor(.red)
                }
            }

            Section(header: Text("Sync Status")) {
                HStack {
                    Label("Cloud Sync", systemImage: "icloud")
                    Spacer()
                    Text("Active")
                        .foregroundColor(.green)
                }

                HStack {
                    Text("Last Backup")
                    Spacer()
                    Text("5 minutes ago")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Data Management")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Clear All History?", isPresented: $showingClearDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                dataService.completedSessions.removeAll()
                HapticManager.shared.success()
            }
        } message: {
            Text("This will permanently delete all completed scan history. This action cannot be undone.")
        }
    }
}

struct DiagnosticsView: View {
    var body: some View {
        List {
            Section(header: Text("System Status")) {
                StatusRow(label: "Camera", status: .operational, icon: "camera")
                StatusRow(label: "AR Engine", status: .operational, icon: "arkit")
                StatusRow(label: "Network", status: .operational, icon: "network")
                StatusRow(label: "Storage", status: .operational, icon: "internaldrive")
            }

            Section(header: Text("Performance Metrics")) {
                HStack {
                    Text("Average Scan Time")
                    Spacer()
                    Text("3.2s")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Detection Accuracy")
                    Spacer()
                    Text("98.5%")
                        .foregroundColor(.green)
                }

                HStack {
                    Text("Frame Rate")
                    Spacer()
                    Text("60 fps")
                        .foregroundColor(.green)
                }
            }

            Section(header: Text("Device Information")) {
                HStack {
                    Text("Device Model")
                    Spacer()
                    Text("iPad Pro")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("iOS Version")
                    Spacer()
                    Text("18.0")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Available Storage")
                    Spacer()
                    Text("125 GB")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Diagnostics")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StatusRow: View {
    let label: String
    let status: SystemStatus
    let icon: String

    enum SystemStatus {
        case operational
        case warning
        case error

        var color: Color {
            switch self {
            case .operational: return .green
            case .warning: return .orange
            case .error: return .red
            }
        }

        var text: String {
            switch self {
            case .operational: return "Operational"
            case .warning: return "Warning"
            case .error: return "Error"
            }
        }
    }

    var body: some View {
        HStack {
            Label(label, systemImage: icon)
            Spacer()
            HStack(spacing: 6) {
                Circle()
                    .fill(status.color)
                    .frame(width: 8, height: 8)
                Text(status.text)
                    .foregroundColor(status.color)
                    .font(.caption)
            }
        }
    }
}
