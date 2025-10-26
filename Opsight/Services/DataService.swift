//
//  DataService.swift
//  Opsight
//

import Foundation
import SwiftUI
import Combine

class DataService: ObservableObject {
    static let shared = DataService()

    @Published var availableFlights: [CartManifest] = []
    @Published var completedSessions: [LoadingSession] = []
    @Published var selectedFlight: CartManifest?

    private init() {
        loadSampleFlights()
    }

    private func loadSampleFlights() {
        let now = Date()

        availableFlights = [
            CartManifest(
                flightNumber: "AA123",
                destination: "LAX",
                aircraftType: "Boeing 737-800",
                departureTime: now.addingTimeInterval(7200), // 2 hours from now
                totalPassengers: 150,
                extraPassengers: 5,
                expectedItems: [
                    MealItem(name: "Chicken Teriyaki", category: .lunch, quantity: 65),
                    MealItem(name: "Vegetarian Pasta", category: .lunch, quantity: 25),
                    MealItem(name: "Gluten-Free Option", category: .specialty, quantity: 8),
                    MealItem(name: "Coca-Cola", category: .beverage, quantity: 80),
                    MealItem(name: "Water Bottles", category: .beverage, quantity: 100),
                    MealItem(name: "Coffee Pods", category: .beverage, quantity: 60),
                    MealItem(name: "Pretzels", category: .snack, quantity: 150),
                    MealItem(name: "Cookies", category: .snack, quantity: 80)
                ],
                specialInstructions: "Extra passengers expected - Gate group verified"
            ),
            CartManifest(
                flightNumber: "UA456",
                destination: "JFK",
                aircraftType: "Airbus A320",
                departureTime: now.addingTimeInterval(5400), // 1.5 hours from now
                totalPassengers: 180,
                extraPassengers: 3,
                expectedItems: [
                    MealItem(name: "Egg & Cheese Croissant", category: .breakfast, quantity: 90),
                    MealItem(name: "Yogurt Parfait", category: .breakfast, quantity: 45),
                    MealItem(name: "Fresh Fruit Bowl", category: .snack, quantity: 60),
                    MealItem(name: "Coffee - Regular", category: .beverage, quantity: 140),
                    MealItem(name: "Orange Juice", category: .beverage, quantity: 80),
                    MealItem(name: "Apple Juice", category: .beverage, quantity: 50),
                    MealItem(name: "Muffins", category: .snack, quantity: 70)
                ],
                specialInstructions: "Morning service - fresh coffee priority"
            ),
            CartManifest(
                flightNumber: "DL789",
                destination: "ORD",
                aircraftType: "Boeing 757-200",
                departureTime: now.addingTimeInterval(10800), // 3 hours from now
                totalPassengers: 200,
                expectedItems: [
                    MealItem(name: "Beef Lasagna", category: .dinner, quantity: 85),
                    MealItem(name: "Chicken Alfredo", category: .dinner, quantity: 70),
                    MealItem(name: "Vegan Quinoa Bowl", category: .specialty, quantity: 18),
                    MealItem(name: "Red Wine", category: .beverage, quantity: 65),
                    MealItem(name: "White Wine", category: .beverage, quantity: 45),
                    MealItem(name: "Soft Drinks", category: .beverage, quantity: 120),
                    MealItem(name: "Dinner Rolls", category: .snack, quantity: 200),
                    MealItem(name: "Chocolate Mousse", category: .snack, quantity: 150)
                ],
                specialInstructions: "Premium service - check wine temperature"
            ),
            CartManifest(
                flightNumber: "WN234",
                destination: "DEN",
                aircraftType: "Boeing 737 MAX",
                departureTime: now.addingTimeInterval(14400), // 4 hours from now
                totalPassengers: 175,
                extraPassengers: 7,
                expectedItems: [
                    MealItem(name: "Turkey Club Sandwich", category: .lunch, quantity: 85),
                    MealItem(name: "Caprese Sandwich", category: .lunch, quantity: 45),
                    MealItem(name: "Peanut-Free Snack Mix", category: .snack, quantity: 175),
                    MealItem(name: "Chips - Assorted", category: .snack, quantity: 120),
                    MealItem(name: "Pepsi Products", category: .beverage, quantity: 100),
                    MealItem(name: "Sprite", category: .beverage, quantity: 60),
                    MealItem(name: "Bottled Water", category: .beverage, quantity: 175),
                    MealItem(name: "Granola Bars", category: .snack, quantity: 90)
                ],
                specialInstructions: "Allergy-conscious - no peanuts in main cabin"
            ),
            CartManifest(
                flightNumber: "BA567",
                destination: "LHR",
                aircraftType: "Boeing 787 Dreamliner",
                departureTime: now.addingTimeInterval(18000), // 5 hours from now
                totalPassengers: 280,
                extraPassengers: 10,
                expectedItems: [
                    MealItem(name: "Beef Wellington", category: .dinner, quantity: 120),
                    MealItem(name: "Sea Bass Fillet", category: .dinner, quantity: 85),
                    MealItem(name: "Vegetarian Curry", category: .specialty, quantity: 35),
                    MealItem(name: "Kosher Meal", category: .specialty, quantity: 12),
                    MealItem(name: "Halal Meal", category: .specialty, quantity: 25),
                    MealItem(name: "Champagne", category: .beverage, quantity: 150),
                    MealItem(name: "Premium Wine Selection", category: .beverage, quantity: 100),
                    MealItem(name: "Spirits - Mini Bottles", category: .beverage, quantity: 80),
                    MealItem(name: "Sparkling Water", category: .beverage, quantity: 200),
                    MealItem(name: "Still Water", category: .beverage, quantity: 200),
                    MealItem(name: "Artisan Bread Selection", category: .snack, quantity: 280),
                    MealItem(name: "Cheese & Crackers", category: .snack, quantity: 150),
                    MealItem(name: "Premium Dessert Selection", category: .snack, quantity: 280)
                ],
                specialInstructions: "Long-haul international - premium service, multiple dietary requirements"
            ),
            CartManifest(
                flightNumber: "F9812",
                destination: "LAS",
                aircraftType: "Airbus A321",
                departureTime: now.addingTimeInterval(21600), // 6 hours from now
                totalPassengers: 220,
                expectedItems: [
                    MealItem(name: "Ham & Swiss Wrap", category: .lunch, quantity: 100),
                    MealItem(name: "Caesar Salad", category: .lunch, quantity: 65),
                    MealItem(name: "Chips - Regular", category: .snack, quantity: 220),
                    MealItem(name: "Candy Bar Selection", category: .snack, quantity: 120),
                    MealItem(name: "Coke Products", category: .beverage, quantity: 150),
                    MealItem(name: "Juice Boxes", category: .beverage, quantity: 80),
                    MealItem(name: "Coffee Service", category: .beverage, quantity: 100)
                ]
            ),
            CartManifest(
                flightNumber: "NK445",
                destination: "MIA",
                aircraftType: "Airbus A320neo",
                departureTime: now.addingTimeInterval(25200), // 7 hours from now
                totalPassengers: 186,
                extraPassengers: 4,
                expectedItems: [
                    MealItem(name: "Chicken Wrap", category: .lunch, quantity: 85),
                    MealItem(name: "Garden Salad", category: .lunch, quantity: 55),
                    MealItem(name: "Pretzels", category: .snack, quantity: 186),
                    MealItem(name: "Trail Mix", category: .snack, quantity: 95),
                    MealItem(name: "Water", category: .beverage, quantity: 186),
                    MealItem(name: "Soft Drinks", category: .beverage, quantity: 120)
                ]
            ),
            CartManifest(
                flightNumber: "AS890",
                destination: "SEA",
                aircraftType: "Boeing 737-900ER",
                departureTime: now.addingTimeInterval(28800), // 8 hours from now
                totalPassengers: 178,
                expectedItems: [
                    MealItem(name: "Pacific Salmon Salad", category: .lunch, quantity: 75),
                    MealItem(name: "Chicken Caesar Wrap", category: .lunch, quantity: 68),
                    MealItem(name: "Local Craft Snacks", category: .snack, quantity: 178),
                    MealItem(name: "Seattle Coffee", category: .beverage, quantity: 140),
                    MealItem(name: "Local Beer", category: .beverage, quantity: 60),
                    MealItem(name: "Sparkling Water", category: .beverage, quantity: 90)
                ],
                specialInstructions: "Regional specialties - highlight local products"
            )
        ]

        // Load sample completed sessions for history
        loadSampleCompletedSessions()
    }

    private func loadSampleCompletedSessions() {
        let calendar = Calendar.current
        let now = Date()

        // Session 1 - Perfect accuracy from earlier today
        let manifest1 = CartManifest(
            flightNumber: "UA789",
            destination: "SFO",
            aircraftType: "Boeing 777-300ER",
            departureTime: calendar.date(byAdding: .hour, value: -3, to: now)!,
            totalPassengers: 350,
            expectedItems: [
                MealItem(name: "Beef Entree", category: .dinner, quantity: 150),
                MealItem(name: "Chicken Entree", category: .dinner, quantity: 120),
                MealItem(name: "Vegetarian Meal", category: .specialty, quantity: 40),
                MealItem(name: "Wine Selection", category: .beverage, quantity: 200),
                MealItem(name: "Soft Drinks", category: .beverage, quantity: 250)
            ]
        )

        let session1 = LoadingSession(
            manifest: manifest1,
            scannedAt: calendar.date(byAdding: .hour, value: -4, to: now)!,
            detectedItems: manifest1.expectedItems,
            status: .completed
        )

        // Session 2 - Good accuracy with minor discrepancy from earlier today
        let manifest2 = CartManifest(
            flightNumber: "AA456",
            destination: "BOS",
            aircraftType: "Airbus A321",
            departureTime: calendar.date(byAdding: .hour, value: -5, to: now)!,
            totalPassengers: 190,
            expectedItems: [
                MealItem(name: "Breakfast Burrito", category: .breakfast, quantity: 85),
                MealItem(name: "Yogurt Parfait", category: .breakfast, quantity: 60),
                MealItem(name: "Coffee", category: .beverage, quantity: 150),
                MealItem(name: "Orange Juice", category: .beverage, quantity: 100)
            ]
        )

        let session2 = LoadingSession(
            manifest: manifest2,
            scannedAt: calendar.date(byAdding: .hour, value: -6, to: now)!,
            detectedItems: [
                MealItem(name: "Breakfast Burrito", category: .breakfast, quantity: 85),
                MealItem(name: "Yogurt Parfait", category: .breakfast, quantity: 58), // 2 missing
                MealItem(name: "Coffee", category: .beverage, quantity: 150),
                MealItem(name: "Orange Juice", category: .beverage, quantity: 100)
            ],
            status: .completed
        )

        // Session 3 - Earlier today with some issues
        let manifest3 = CartManifest(
            flightNumber: "DL234",
            destination: "ATL",
            aircraftType: "Boeing 737-900",
            departureTime: calendar.date(byAdding: .hour, value: -7, to: now)!,
            totalPassengers: 170,
            expectedItems: [
                MealItem(name: "Turkey Sandwich", category: .lunch, quantity: 75),
                MealItem(name: "Chips", category: .snack, quantity: 170),
                MealItem(name: "Cookies", category: .snack, quantity: 85),
                MealItem(name: "Soft Drinks", category: .beverage, quantity: 120)
            ]
        )

        let session3 = LoadingSession(
            manifest: manifest3,
            scannedAt: calendar.date(byAdding: .hour, value: -8, to: now)!,
            detectedItems: [
                MealItem(name: "Turkey Sandwich", category: .lunch, quantity: 75),
                MealItem(name: "Chips", category: .snack, quantity: 168), // 2 missing
                MealItem(name: "Cookies", category: .snack, quantity: 88), // 3 extra
                MealItem(name: "Soft Drinks", category: .beverage, quantity: 120)
            ],
            status: .completed
        )

        // Session 4 - Yesterday session
        let manifest4 = CartManifest(
            flightNumber: "WN567",
            destination: "PHX",
            aircraftType: "Boeing 737-800",
            departureTime: calendar.date(byAdding: .day, value: -1, to: now)!,
            totalPassengers: 143,
            expectedItems: [
                MealItem(name: "Mixed Nuts", category: .snack, quantity: 143),
                MealItem(name: "Pretzels", category: .snack, quantity: 143),
                MealItem(name: "Beverages", category: .beverage, quantity: 200)
            ]
        )

        let session4 = LoadingSession(
            manifest: manifest4,
            scannedAt: calendar.date(byAdding: .day, value: -1, to: now)!,
            detectedItems: manifest4.expectedItems,
            status: .completed
        )

        // Session 5 - Yesterday with perfect score
        let manifest5 = CartManifest(
            flightNumber: "B6890",
            destination: "FLL",
            aircraftType: "Airbus A320",
            departureTime: calendar.date(byAdding: .day, value: -1, to: now)!,
            totalPassengers: 162,
            expectedItems: [
                MealItem(name: "Chicken Wrap", category: .lunch, quantity: 80),
                MealItem(name: "Veggie Wrap", category: .lunch, quantity: 45),
                MealItem(name: "Chips", category: .snack, quantity: 162),
                MealItem(name: "Water", category: .beverage, quantity: 162)
            ]
        )

        let session5 = LoadingSession(
            manifest: manifest5,
            scannedAt: calendar.date(byAdding: .day, value: -1, to: now)!,
            detectedItems: manifest5.expectedItems,
            status: .completed
        )

        completedSessions = [session1, session2, session3, session4, session5]
    }

    func selectFlight(_ flight: CartManifest) {
        selectedFlight = flight
    }

    func completeSession(_ session: LoadingSession) {
        completedSessions.insert(session, at: 0)

        // Remove the flight from available flights
        if let index = availableFlights.firstIndex(where: { $0.id == session.manifest.id }) {
            availableFlights.remove(at: index)
        }
    }

    func todaySessions() -> [LoadingSession] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return completedSessions.filter { session in
            calendar.isDate(session.scannedAt, inSameDayAs: today)
        }
    }

    func averageAccuracy() -> Double {
        let sessions = todaySessions()
        guard sessions.count > 0 else { return 0 }

        let total = sessions.reduce(0.0) { $0 + $1.accuracy }
        return total / Double(sessions.count)
    }

    func totalCartsLoaded() -> Int {
        return todaySessions().count
    }
}
