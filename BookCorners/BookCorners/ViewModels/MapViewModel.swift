//
//  MapViewModel.swift
//  BookCorners
//
//  Created by Andrea Grandi on 21/03/26.
//

import Foundation
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

    func loadLibraries(lat: Double, lng: Double, radiusKm: Int) {
        loadTask?.cancel()

        loadTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(300))
                try Task.checkCancellation()
                isLoading = true
                let response = try await apiClient.getLibraries(
                    page: 1, pageSize: 50, query: nil, city: nil, country: nil,
                    lat: lat, lng: lng, radiusKm: radiusKm, hasPhoto: nil,
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
}
