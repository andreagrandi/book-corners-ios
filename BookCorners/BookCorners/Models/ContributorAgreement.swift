//
//  ContributorAgreement.swift
//  BookCorners
//

import Foundation

nonisolated enum ContributorAgreement {
    struct Acceptance: Equatable {
        let version: String
        let accepted: Bool
    }

    static let currentVersion = "1.0"
    static let publishedURL = URL(
        string: "https://bookcorners.org/contributor-agreement/1.0/en/",
    )!
    static let currentAcceptance = Acceptance(
        version: currentVersion,
        accepted: true,
    )

    static var presentationURL: URL {
        #if DEBUG
            if let override = ProcessInfo.processInfo.environment["CONTRIBUTOR_AGREEMENT_URL"],
               let url = URL(string: override)
            {
                return url
            }
        #endif
        return publishedURL
    }
}
