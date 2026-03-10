//
//  Library.swift
//  BookCorners
//
//  Created by Andrea Grandi on 10/03/26.
//

import Foundation

struct Library: Codable, Identifiable {
      let id: Int
      let slug: String
      let name: String
      let description: String
      let photoURL: String
      let thumbnailURL: String
      let lat: Double
      let lng: Double
      let address: String
      let city: String
      let country: String
      let postalCode: String
      let wheelchairAccessible: String
      let capacity: Int?
      let isIndoor: Bool?
      let isLit: Bool?
      let website: String
      let contact: String
      let source: String
      let operatorName: String
      let brand: String
      let createdAt: Date

      enum CodingKeys: String, CodingKey {
          case id, slug, name, description
          case photoURL = "photo_url"
          case thumbnailURL = "thumbnail_url"
          case lat, lng, address, city, country
          case postalCode = "postal_code"
          case wheelchairAccessible = "wheelchair_accessible"
          case capacity
          case isIndoor = "is_indoor"
          case isLit = "is_lit"
          case website, contact, source
          case operatorName = "operator"
          case brand
          case createdAt = "created_at"
      }
  }
