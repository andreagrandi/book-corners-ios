//
//  LatestLibrariesResponse.swift
//  BookCorners
//
//  Created by Andrea Grandi on 10/03/26.
//

import Foundation

nonisolated struct LatestLibrariesResponse: Codable {
    let items: [Library]
}
