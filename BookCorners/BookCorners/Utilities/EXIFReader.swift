//
//  EXIFReader.swift
//  BookCorners
//

import CoreLocation
import ImageIO

enum EXIFReader {
    static func extractCoordinates(from data: Data) -> CLLocationCoordinate2D? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
              let gps = properties[kCGImagePropertyGPSDictionary as String] as? [String: Any],
              let latitude = gps[kCGImagePropertyGPSLatitude as String] as? Double,
              let latitudeRef = gps[kCGImagePropertyGPSLatitudeRef as String] as? String,
              let longitude = gps[kCGImagePropertyGPSLongitude as String] as? Double,
              let longitudeRef = gps[kCGImagePropertyGPSLongitudeRef as String] as? String
        else {
            return nil
        }

        let lat = latitudeRef == "S" ? -latitude : latitude
        let lng = longitudeRef == "W" ? -longitude : longitude

        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
}
