//
//  HapticManager.swift
//  Opsight
//
//  Created by toño on 25/10/25.
//

import UIKit
import Combine

class HapticManager: ObservableObject {
    static let shared = HapticManager()
    
    private let successFeedback = UINotificationFeedbackGenerator()
    private let errorFeedback = UINotificationFeedbackGenerator()
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    private init() {
        successFeedback.prepare()
        errorFeedback.prepare()
        selectionFeedback.prepare()
        impactFeedback.prepare()
    }
    
    func success() {
        successFeedback.notificationOccurred(.success)
    }
    
    func error() {
        errorFeedback.notificationOccurred(.error)
    }
    
    func warning() {
        errorFeedback.notificationOccurred(.warning)
    }
    
    func selection() {
        selectionFeedback.selectionChanged()
    }
    
    func impact() {
        impactFeedback.impactOccurred()
    }
}
