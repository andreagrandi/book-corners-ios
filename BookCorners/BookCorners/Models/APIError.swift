//
//  APIError.swift
//  BookCorners
//
//  Created by Andrea Grandi on 10/03/26.
//

import Foundation

struct APIErrorResponse: Codable {
    let message: String
    let details: [String: String]?
}
