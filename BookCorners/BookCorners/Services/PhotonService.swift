//
//  PhotonService.swift
//  BookCorners
//

import Foundation

struct PhotonService {
    private static let baseURL = "https://photon.komoot.io/api/"

    func search(query: String) async throws -> [PhotonFeature] {
        guard !query.isEmpty,
              var components = URLComponents(string: PhotonService.baseURL)
        else {
            return []
        }

        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: "5"),
        ]

        guard let url = components.url else { return [] }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(PhotonResponse.self, from: data)
        return response.features
    }
}
