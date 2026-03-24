//
//  DirectionsServiceTests.swift
//  BookCornersTests
//

@testable import BookCorners
import Testing

struct DirectionsServiceTests {
    @Test func `google maps URL contains coordinates and walking mode`() {
        let url = DirectionsService.googleMapsURL(latitude: 48.8566, longitude: 2.3522)

        #expect(url.contains("daddr=48.8566,2.3522"))
        #expect(url.contains("directionsmode=walking"))
        #expect(url.hasPrefix("comgooglemaps://"))
    }

    @Test func `available apps always includes Apple Maps`() async {
        let apps = await DirectionsService.availableApps()

        #expect(apps.contains(.appleMaps))
    }

    @Test func `MapApp raw values are display names`() {
        #expect(MapApp.appleMaps.rawValue == "Apple Maps")
        #expect(MapApp.googleMaps.rawValue == "Google Maps")
    }
}
