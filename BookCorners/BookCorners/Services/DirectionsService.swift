//
//  DirectionsService.swift
//  BookCorners
//

import CoreLocation
import MapKit
import UIKit

enum MapApp: String, CaseIterable, Identifiable {
    case appleMaps = "Apple Maps"
    case googleMaps = "Google Maps"

    var id: String {
        rawValue
    }
}

enum DirectionsService {
    private static let googleMapsScheme = "comgooglemaps://"

    static func availableApps() -> [MapApp] {
        var apps: [MapApp] = [.appleMaps]
        if let url = URL(string: googleMapsScheme),
           UIApplication.shared.canOpenURL(url)
        {
            apps.append(.googleMaps)
        }
        return apps
    }

    static func openDirections(
        to coordinate: CLLocationCoordinate2D,
        name: String,
        using app: MapApp,
    ) {
        switch app {
        case .appleMaps:
            let mapItem = MKMapItem(
                placemark: MKPlacemark(coordinate: coordinate),
            )
            mapItem.name = name
            mapItem.openInMaps(launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking,
            ])
        case .googleMaps:
            let urlString = "comgooglemaps://?daddr=\(coordinate.latitude),\(coordinate.longitude)&directionsmode=walking"
            if let url = URL(string: urlString) {
                UIApplication.shared.open(url)
            }
        }
    }

    static func googleMapsURL(latitude: Double, longitude: Double) -> String {
        "comgooglemaps://?daddr=\(latitude),\(longitude)&directionsmode=walking"
    }
}
