//
//  AccessibilityManager.swift
//  Opsight
//
//  Created by toño on 24/10/25.
//

import SwiftUI
import Combine

class AccessibilityManager: ObservableObject {
    @Published var isVoiceOverRunning: Bool
    @Published var preferredContentSize: ContentSizeCategory
    
    init() {
        self.isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
        self.preferredContentSize = ContentSizeCategory(UIApplication.shared.preferredContentSizeCategory)!
        
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
        }
    }
    
    func announceForAccesibility(_ message: String) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }
}
