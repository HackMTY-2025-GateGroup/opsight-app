//
//  WarehouseWorkflowView.swift
//  Opsight
//
//  Created by Claude on 25/10/25.
//

import SwiftUI
import Combine

/// Main warehouse worker interface optimized for tablet use
/// Guides workers through cart preparation with FEFO batch selection
struct WarehouseWorkflowView: View {
    @EnvironmentObject var accessibilityManager: AccessibilityManager
    @StateObject private var viewModel = WarehouseWorkflowViewModel()
    @State private var selectedWorkflow: WorkflowType = .cartPreparation

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Workflow selector
                WorkflowSelector(selectedWorkflow: $selectedWorkflow)
                    .padding()

                Divider()

                // Main content area
                ScrollView {
                    VStack(spacing: 20) {
                        switch selectedWorkflow {
                        case .cartPreparation:
                            CartPreparationWorkflow()
                        case .returnProcessing:
                            ReturnProcessingWorkflow()
                        case .inventoryCheck:
                            InventoryCheckWorkflow()
                        case .wasteRecording:
                            WasteRecordingWorkflow()
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Warehouse Operations")
            .navigationBarTitleDisplayMode(.inline)
        }
        .navigationViewStyle(.stack)
    }
}

enum WorkflowType: String, CaseIterable {
    case cartPreparation = "Cart Preparation"
    case returnProcessing = "Process Returns"
    case inventoryCheck = "Inventory Check"
    case wasteRecording = "Record Waste"

    var icon: String {
        switch self {
        case .cartPreparation: return "cart.fill"
        case .returnProcessing: return "arrow.uturn.backward.circle.fill"
        case .inventoryCheck: return "cube.box.fill"
        case .wasteRecording: return "trash.fill"
        }
    }

    var color: Color {
        switch self {
        case .cartPreparation: return .blue
        case .returnProcessing: return .orange
        case .inventoryCheck: return .green
        case .wasteRecording: return .red
        }
    }
}

/// Workflow selector tabs optimized for large touch targets
struct WorkflowSelector: View {
    @Binding var selectedWorkflow: WorkflowType

    var body: some View {
        HStack(spacing: 12) {
            ForEach(WorkflowType.allCases, id: \.self) { workflow in
                WorkflowTab(
                    workflow: workflow,
                    isSelected: selectedWorkflow == workflow
                )
                .onTapGesture {
                    HapticManager.shared.selection()
                    selectedWorkflow = workflow
                }
            }
        }
    }
}

struct WorkflowTab: View {
    let workflow: WorkflowType
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: workflow.icon)
                .font(.system(size: 28))
                .foregroundColor(isSelected ? .white : workflow.color)

            Text(workflow.rawValue)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(isSelected ? workflow.color : Color.gray.opacity(0.1))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(workflow.rawValue)")
        .accessibilityHint(isSelected ? "Selected" : "Tap to switch workflow")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

/// Cart preparation workflow with FEFO batch guidance
struct CartPreparationWorkflow: View {
    @EnvironmentObject var accessibilityManager: AccessibilityManager
    @StateObject private var viewModel = CartPreparationViewModel()

    var body: some View {
        VStack(spacing: 24) {
            // Flight selection
            FlightSelectionCard(selectedFlight: $viewModel.selectedManifest)

            if let manifest = viewModel.selectedManifest {
                // Cart preparation checklist
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "list.clipboard.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                        Text("Loading Checklist")
                            .font(.title2)
                            .fontWeight(.bold)
                    }

                    // Items to load with batch recommendations
                    ForEach(manifest.expectedItems) { item in
                        CartItemCard(
                            item: item,
                            batchAssignments: manifest.batchAssignments?.filter { $0.productId == item.id }
                        )
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)

                // Action buttons
                HStack(spacing: 16) {
                    Button(action: {
                        HapticManager.shared.impact()
                        viewModel.scanCart()
                    }) {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Scan Cart")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .accessibilityLabel("Scan cart to verify contents")

                    Button(action: {
                        HapticManager.shared.impact()
                        viewModel.completeManually()
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Complete")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .accessibilityLabel("Mark cart as complete")
                }
            } else {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "airplane.circle")
                        .font(.system(size: 64))
                        .foregroundColor(.gray)
                    Text("Select a flight to begin cart preparation")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            }
        }
        .fullScreenCover(isPresented: $viewModel.showARCamera) {
            if let manifest = viewModel.selectedManifest {
                ARTrolleyView(manifest: manifest)
                    .environmentObject(accessibilityManager)
            }
        }
    }
}

/// Card showing batch recommendations with FEFO priority
struct CartItemCard: View {
    let item: MealItem
    let batchAssignments: [BatchAssignment]?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                    Text("\(item.quantity) required")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Quantity badge
                Text("\(item.quantity)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Color.blue)
                    .clipShape(Circle())
            }

            // Batch recommendations
            if let batches = batchAssignments, !batches.isEmpty {
                VStack(spacing: 8) {
                    ForEach(batches) { batch in
                        BatchRecommendationRow(batch: batch)
                    }
                }
            } else {
                Text("Use any available batch")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.name), \(item.quantity) required")
    }
}

/// Shows recommended batch with expiration info
struct BatchRecommendationRow: View {
    let batch: BatchAssignment

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Batch: \(batch.batchNumber)")
                    .font(.caption)
                    .fontWeight(.medium)
                Text("Expires: \(formattedDate(batch.expirationDate))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Expiration indicator
            HStack(spacing: 4) {
                Image(systemName: "clock.fill")
                    .font(.caption)
                Text("\(batch.daysUntilExpiry)d")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(expiryColor(batch.daysUntilExpiry))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(expiryColor(batch.daysUntilExpiry).opacity(0.15))
            .cornerRadius(6)

            Text("\(batch.quantityAssigned)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(Color.blue.opacity(0.8))
                .clipShape(Circle())
        }
        .padding(8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Use batch \(batch.batchNumber), \(batch.quantityAssigned) items, expires in \(batch.daysUntilExpiry) days")
    }

    private func expiryColor(_ days: Int) -> Color {
        if days < 5 {
            return .red
        } else if days <= 7 {
            return .orange
        } else {
            return .green
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

/// Flight selection card for tablet
struct FlightSelectionCard: View {
    @Binding var selectedFlight: CartManifest?
    @State private var showingFlightPicker = false

    var body: some View {
        Button(action: {
            HapticManager.shared.selection()
            showingFlightPicker = true
        }) {
            HStack {
                Image(systemName: "airplane.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)

                if let flight = selectedFlight {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Flight \(flight.flightNumber)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("\(flight.destination) • \(flight.totalPassengers) pax")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Select Flight")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
        }
        .accessibilityLabel(selectedFlight != nil ? "Flight \(selectedFlight!.flightNumber) selected" : "Select a flight")
        .accessibilityHint("Tap to change flight")
        .sheet(isPresented: $showingFlightPicker) {
            // Flight picker sheet would go here
            Text("Flight Picker")
        }
    }
}

/// Processing returned carts from aircraft
struct ReturnProcessingWorkflow: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.uturn.backward.circle")
                .font(.system(size: 64))
                .foregroundColor(.orange)
            Text("Return Processing")
                .font(.title2)
                .fontWeight(.bold)
            Text("Scan returned carts to process restock and waste")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

/// Inventory checking workflow
struct InventoryCheckWorkflow: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "cube.box")
                .font(.system(size: 64))
                .foregroundColor(.green)
            Text("Inventory Check")
                .font(.title2)
                .fontWeight(.bold)
            Text("Scan products to verify stock levels and expiration dates")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

/// Waste recording workflow
struct WasteRecordingWorkflow: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "trash.circle")
                .font(.system(size: 64))
                .foregroundColor(.red)
            Text("Record Waste")
                .font(.title2)
                .fontWeight(.bold)
            Text("Document discarded items for waste tracking")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - ViewModels

class WarehouseWorkflowViewModel: ObservableObject {
    @Published var activeWorkflow: WorkflowType = .cartPreparation
}

class CartPreparationViewModel: ObservableObject {
    @Published var selectedManifest: CartManifest?
    @Published var isLoading = false
    @Published var showARCamera = false

    func scanCart() {
        // Trigger AR camera for cart scanning
        HapticManager.shared.impact()
        showARCamera = true
    }

    func completeManually() {
        // Mark cart as complete without scanning
        HapticManager.shared.success()
        // Implementation would go here
    }
}

#Preview {
    WarehouseWorkflowView()
        .environmentObject(AccessibilityManager())
}
