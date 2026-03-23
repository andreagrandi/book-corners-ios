//
//  PhotonResult.swift
//  BookCorners
//

import CoreLocation
import Foundation

struct PhotonResponse: Codable {
    let features: [PhotonFeature]
}

struct PhotonFeature: Codable, Identifiable {
    let properties: PhotonProperties
    let geometry: PhotonGeometry

    var id: String {
        "\(geometry.coordinates[0]),\(geometry.coordinates[1])"
    }

    var coordinate: CLLocationCoordinate2D {
        // GeoJSON is [longitude, latitude]
        CLLocationCoordinate2D(
            latitude: geometry.coordinates[1],
            longitude: geometry.coordinates[0],
        )
    }

    var displayText: String {
        var parts: [String] = []
        if let street = properties.street {
            if let number = properties.housenumber {
                parts.append("\(street) \(number)")
            } else {
                parts.append(street)
            }
        } else if let name = properties.name {
            parts.append(name)
        }
        if let city = properties.city {
            parts.append(city)
        }
        if let countrycode = properties.countrycode {
            parts.append(countrycode)
        }
        return parts.joined(separator: ", ")
    }
}

struct PhotonProperties: Codable {
    let name: String?
    let street: String?
    let housenumber: String?
    let city: String?
    let countrycode: String?
    let postcode: String?
    let state: String?
    let country: String?
}

struct PhotonGeometry: Codable {
    let coordinates: [Double]
}
