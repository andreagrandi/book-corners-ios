//
//  CLLocation+Distance.swift
//  BookCorners
//
//  Created by Andrea Grandi on 17/03/26.
//

import CoreLocation

extension Library {
    func distance(from location: CLLocation) -> CLLocationDistance {
        CLLocation(latitude: lat, longitude: lng).distance(from: location)
    }
}

extension CLLocationDistance {
    var formattedForDisplay: String {
        if self < 1000 {
            return "\(Int(rounded())) m"
        } else {
            let kilometers = self / 1000
            return "\(kilometers.formatted(.number.precision(.fractionLength(1)))) km"
        }
    }
}
