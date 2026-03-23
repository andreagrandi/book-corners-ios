//
//  MapViewModel.swift
//  BookCorners
//
//  Created by Andrea Grandi on 21/03/26.
//

import CoreLocation
import Foundation
import MapKit
import Observation

@Observable
class MapViewModel {
    private let apiClient: APIClientProtocol
    var libraries: [Library] = []
    var isLoading = false
    var errorMessage: String?
    var selectedLibrary: Library?
    private var loadTask: Task<Void, Never>?

    init(client: any APIClientProtocol) {
        apiClient = client
    }

    func loadLibraries(lat: Double, lng: Double, radiusKm: Int, filters: FilterState = FilterState()) {
        loadTask?.cancel()

        let hasLocationFilter = !filters.city.isEmpty || !filters.country.isEmpty || !filters.postalCode.isEmpty

        loadTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(300))
                try Task.checkCancellation()
                isLoading = true
                let response = try await apiClient.getLibraries(
                    page: 1, pageSize: 50,
                    query: filters.keywords.isEmpty ? nil : filters.keywords,
                    city: filters.city.isEmpty ? nil : filters.city,
                    country: filters.country.isEmpty ? nil : filters.country,
                    postalCode: filters.postalCode.isEmpty ? nil : filters.postalCode,
                    lat: hasLocationFilter ? nil : lat,
                    lng: hasLocationFilter ? nil : lng,
                    radiusKm: hasLocationFilter ? nil : radiusKm,
                    hasPhoto: nil,
                )
                libraries = response.items
                isLoading = false
            } catch is CancellationError {
                // debounce cancelled — perfectly normal, do nothing
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    /// Loads libraries with filters applied. No debounce — called directly when user taps Apply.
    func applyFilters(_ filters: FilterState) async {
        loadTask?.cancel()
        isLoading = true
        errorMessage = nil

        let hasLocationFilter = !filters.city.isEmpty || !filters.country.isEmpty || !filters.postalCode.isEmpty

        do {
            let response = try await apiClient.getLibraries(
                page: 1, pageSize: 50,
                query: filters.keywords.isEmpty ? nil : filters.keywords,
                city: filters.city.isEmpty ? nil : filters.city,
                country: filters.country.isEmpty ? nil : filters.country,
                postalCode: filters.postalCode.isEmpty ? nil : filters.postalCode,
                lat: hasLocationFilter ? nil : nil,
                lng: hasLocationFilter ? nil : nil,
                radiusKm: hasLocationFilter ? nil : filters.radiusKm,
                hasPhoto: nil,
            )
            libraries = response.items
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    /// Computes a map region that fits all current libraries.
    func regionForResults() -> MKCoordinateRegion? {
        guard !libraries.isEmpty else { return nil }

        var minLat = Double.greatestFiniteMagnitude
        var maxLat = -Double.greatestFiniteMagnitude
        var minLng = Double.greatestFiniteMagnitude
        var maxLng = -Double.greatestFiniteMagnitude

        for library in libraries {
            minLat = min(minLat, library.lat)
            maxLat = max(maxLat, library.lat)
            minLng = min(minLng, library.lng)
            maxLng = max(maxLng, library.lng)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLng + maxLng) / 2,
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.3, 0.01),
            longitudeDelta: max((maxLng - minLng) * 1.3, 0.01),
        )
        return MKCoordinateRegion(center: center, span: span)
    }
}
