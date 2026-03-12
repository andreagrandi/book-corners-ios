//
//  Report.swift
//  BookCorners
//
//  Created by Andrea Grandi on 10/03/26.
//

import Foundation

nonisolated enum ReportReason: String, Codable, CaseIterable {
    case damaged
    case missing
    case incorrectInfo = "incorrect_info"
    case inappropriate
    case other
}

nonisolated struct Report: Codable, Identifiable {
    let id: Int
    let reason: String
    let createdAt: Date
}
