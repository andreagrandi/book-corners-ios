//
//  LibraryPhoto.swift
//  BookCorners
//
//  Created by Andrea Grandi on 10/03/26.
//

import Foundation

struct LibraryPhoto: Codable, Identifiable {
    let id: Int
    let caption: String
    let status: String
    let createdAt: Date
}
