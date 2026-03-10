//
//  APIClientError.swift
//  BookCorners
//
//  Created by Andrea Grandi on 10/03/26.
//

import Foundation

enum APIClientError: Error, LocalizedError {
    case invalidURL
    case httpError(statusCode: Int, message: String)
    case unauthorized
    case rateLimited(retryAfter: Int?)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case let .httpError(statusCode, message):
            return "HTTP \(statusCode): \(message)"
        case .unauthorized:
            return "Authentication required"
        case let .rateLimited(retryAfter):
            if let seconds = retryAfter {
                return "Too many requests. Try again in \(seconds) seconds."
            }
            return "Too many requests. Please try again later."
        case let .decodingError(error):
            return "Failed to decode response: \(error.localizedDescription)"
        case let .networkError(error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
