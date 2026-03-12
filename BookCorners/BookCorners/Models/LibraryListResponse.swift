//
//  LibraryListResponse.swift
//  BookCorners
//
//  Created by Andrea Grandi on 10/03/26.
//

import Foundation

nonisolated struct LibraryListResponse: Codable {
    let items: [Library]
    let pagination: PaginationMeta
}

nonisolated struct PaginationMeta: Codable {
    let page: Int
    let pageSize: Int
    let total: Int
    let totalPages: Int
    let hasNext: Bool
    let hasPrevious: Bool
}
