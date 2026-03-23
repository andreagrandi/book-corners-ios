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

    var displayName: String {
        switch self {
        case .damaged: "Damaged"
        case .missing: "Missing"
        case .incorrectInfo: "Incorrect Information"
        case .inappropriate: "Inappropriate"
        case .other: "Other"
        }
    }
}

nonisolated struct Report: Codable, Identifiable {
    let id: Int
    let reason: String
    let createdAt: Date
}
