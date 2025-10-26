//
//  ContentView.swift
//  Opsight
//
//  Created by toño on 24/10/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var accessibilityManager: AccessibilityManager
    @StateObject private var hapticManager = HapticManager.shared

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .accessibilityLabel("Home tab")

            WarehouseWorkflowView()
                .tabItem {
                    Label("Warehouse", systemImage: "building.2.fill")
                }
                .accessibilityLabel("Warehouse operations tab")

            CartLoadingView()
                .tabItem {
                    Label("Scan", systemImage: "camera.fill")
                }
                .accessibilityLabel("Scan cart tab")

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .accessibilityLabel("History tab")

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .accessibilityLabel("Settings tab")
        }
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
        .environmentObject(AccessibilityManager())
}
