//
//  OpenStreetMapContributionNotice.swift
//  BookCorners
//
//  Created by Andrea Grandi on 30/07/26.
//

import SwiftUI

struct OpenStreetMapContributionNotice: View {
    private static let privacyPolicyURL = URL(string: "https://www.bookcorners.org/privacy/")!

    var body: some View {
        Section {
            Text(
                "In the future, we may add approved library locations to OpenStreetMap.",
            )
            .accessibilityIdentifier("osm-contribution-notice")

            Link(
                "Read our privacy policy.",
                destination: Self.privacyPolicyURL,
            )
            .accessibilityHint("Opens the Book Corners privacy policy")
            .accessibilityIdentifier("osm-contribution-privacy-policy-link")
        } header: {
            Label("About your submission", systemImage: "info.circle")
        }
    }
}

#Preview {
    Form {
        OpenStreetMapContributionNotice()
    }
}
