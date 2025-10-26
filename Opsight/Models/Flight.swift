//
//  Flight.swift
//  Opsight
//
//  Created by toño on 25/10/25.
//

import Foundation

struct Flight: Identifiable, Codable {
    let id: UUID
    let aircraftId: UUID?
    let flightNumber: String?
    let departureAt: Date?
    let arrivalAt: Date?
    let origin: String?
    let destination: String?
    let createdAt: Date
    
    // Extended properties (not in DB, loaded via joins)
    var aircraft: Aircraft?
    var trolleys: [Trolley]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case aircraftId = "aircraft_id"
        case flightNumber = "flight_number"
        case departureAt = "departure_at"
        case arrivalAt = "arrival_at"
        case origin
        case destination
        case createdAt = "created_at"
    }
    
    init(id: UUID = UUID(), aircraftId: UUID? = nil, flightNumber: String? = nil, departureAt: Date? = nil, arrivalAt: Date? = nil, origin: String? = nil, destination: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.aircraftId = aircraftId
        self.flightNumber = flightNumber
        self.departureAt = departureAt
        self.arrivalAt = arrivalAt
        self.origin = origin
        self.destination = destination
        self.createdAt = createdAt
    }
    
    var formattedFlightNumber: String {
        flightNumber ?? "Unknown"
    }
    
    var route: String {
        guard let origin = origin, let destination = destination else {
            return "Unknown Route"
        }
        return "\(origin) → \(destination)"
    }
    
    var departureTime: String {
        guard let departure = departureAt else { return "TBD" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: departure)
    }
}
