//
//  MealItem.swift
//  Opsight
//
//  Created by toño on 25/10/25.
//

import Foundation
import SwiftUI

/// Represents a meal or product item on a cart
struct MealItem: Identifiable, Codable {
    let id: UUID
    let name: String
    let category: ItemCategory
    let quantity: Int

    init(
        id: UUID = UUID(),
        name: String,
        category: ItemCategory,
        quantity: Int
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.quantity = quantity
    }

    enum ItemCategory: String, Codable, CaseIterable {
        case breakfast = "Breakfast"
        case lunch = "Lunch"
        case dinner = "Dinner"
        case snack = "Snack"
        case beverage = "Beverage"
        case specialty = "Specialty"

        var icon: String {
            switch self {
            case .breakfast: return "sunrise.fill"
            case .lunch: return "sun.max.fill"
            case .dinner: return "moon.stars.fill"
            case .snack: return "takeoutbag.and.cup.and.straw.fill"
            case .beverage: return "cup.and.saucer.fill"
            case .specialty: return "star.fill"
            }
        }

        var color: Color {
            switch self {
            case .breakfast: return .orange
            case .lunch: return .yellow
            case .dinner: return .purple
            case .snack: return .green
            case .beverage: return .blue
            case .specialty: return .pink
            }
        }
    }
}
