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
    private var lastLoadedLat: Double?
    private var lastLoadedLng: Double?
    private var lastLoadedRadius: Int?

    init(client: any APIClientProtocol) {
        apiClient = client
    }

    func loadLibraries(lat: Double, lng: Double, radiusKm: Int, filters: FilterState = FilterState()) {
        // Skip reload if the map barely moved (prevents feedback loop from annotation layout shifts)
        if let lastLat = lastLoadedLat, let lastLng = lastLoadedLng, let lastRadius = lastLoadedRadius,
           abs(lat - lastLat) < 0.001, abs(lng - lastLng) < 0.001, radiusKm == lastRadius
        {
            return
        }

        loadTask?.cancel()

        loadTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(300))
                try Task.checkCancellation()
                isLoading = true
                errorMessage = nil
                let response = try await apiClient.getLibraries(
                    page: 1, pageSize: 50,
                    query: filters.keywords.isEmpty ? nil : filters.keywords,
                    city: filters.city.isEmpty ? nil : filters.city,
                    country: filters.country.isEmpty ? nil : filters.country,
                    postalCode: filters.postalCode.isEmpty ? nil : filters.postalCode,
                    lat: lat, lng: lng, radiusKm: radiusKm,
                    hasPhoto: nil,
                )
                libraries = response.items
                lastLoadedLat = lat
                lastLoadedLng = lng
                lastLoadedRadius = radiusKm
                isLoading = false
            } catch is CancellationError {
                // debounce cancelled — perfectly normal, do nothing
            } catch let urlError as URLError where urlError.code == .cancelled {
                // URLSession request cancelled by debounce — also normal
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }

    /// Loads libraries with filters applied. No debounce — called directly when user taps Apply.
    /// Fetches without spatial bounds so the map can zoom to the results.
    /// After zooming, `onMapCameraChange` re-fetches with the visible region.
    func applyFilters(_ filters: FilterState) async {
        loadTask?.cancel()
        lastLoadedLat = nil
        lastLoadedLng = nil
        lastLoadedRadius = nil
        isLoading = true
        errorMessage = nil

        do {
            let response = try await apiClient.getLibraries(
                page: 1, pageSize: 50,
                query: filters.keywords.isEmpty ? nil : filters.keywords,
                city: filters.city.isEmpty ? nil : filters.city,
                country: filters.country.isEmpty ? nil : filters.country,
                postalCode: filters.postalCode.isEmpty ? nil : filters.postalCode,
                lat: nil, lng: nil, radiusKm: nil,
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
