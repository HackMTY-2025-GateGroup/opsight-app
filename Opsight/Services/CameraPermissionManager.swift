//
//  CameraPermissionManager.swift
//  Opsight
//
//  Camera permission management
//

import AVFoundation
import SwiftUI
import Combine

/// Manages camera permissions for AR scanning
class CameraPermissionManager: ObservableObject {
    @Published var authorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published var showPermissionAlert = false

    static let shared = CameraPermissionManager()

    private init() {
        checkCurrentStatus()
    }

    /// Check current camera authorization status
    func checkCurrentStatus() {
        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }

    /// Request camera permission
    func requestPermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            DispatchQueue.main.async {
                self?.authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
                completion(granted)
            }
        }
    }

    /// Check if camera is authorized
    var isCameraAuthorized: Bool {
        return authorizationStatus == .authorized
    }

    /// Request permission if needed
    func ensurePermission(completion: @escaping (Bool) -> Void) {
        switch authorizationStatus {
        case .authorized:
            completion(true)

        case .notDetermined:
            requestPermission(completion: completion)

        case .denied, .restricted:
            DispatchQueue.main.async {
                self.showPermissionAlert = true
            }
            completion(false)

        @unknown default:
            completion(false)
        }
    }
}

/// View to request camera permission before showing AR
struct CameraPermissionView: View {
    @StateObject private var permissionManager = CameraPermissionManager.shared
    @Environment(\.dismiss) private var dismiss
    let onAuthorized: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "camera.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            Text("Camera Access Required")
                .font(.title2)
                .fontWeight(.bold)

            Text("Opsight needs camera access to scan airline trolley carts using AR technology.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)

            Spacer()

            Button(action: {
                permissionManager.requestPermission { granted in
                    if granted {
                        HapticManager.shared.success()
                        onAuthorized()
                    } else {
                        HapticManager.shared.error()
                    }
                }
            }) {
                Text("Enable Camera Access")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)

            Button(action: {
                dismiss()
            }) {
                Text("Not Now")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 40)
        }
        .onAppear {
            permissionManager.checkCurrentStatus()

            // Auto-dismiss if already authorized
            if permissionManager.isCameraAuthorized {
                onAuthorized()
            }
        }
        .alert("Camera Access Denied", isPresented: $permissionManager.showPermissionAlert) {
            Button("Settings", action: {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            })
            Button("Cancel", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Please enable camera access in Settings to use AR scanning.")
        }
    }
}
