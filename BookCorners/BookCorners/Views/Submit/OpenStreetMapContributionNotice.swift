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
                "After moderation, factual location data from approved submissions "
                    + "may be contributed to OpenStreetMap in the future.",
            )
            .accessibilityIdentifier("osm-contribution-notice")

            Link(
                "Learn more in our privacy policy.",
                destination: Self.privacyPolicyURL,
            )
            .accessibilityHint("Opens the Book Corners privacy policy")
            .accessibilityIdentifier("osm-contribution-privacy-policy-link")
        } header: {
            Label("Future OpenStreetMap contributions", systemImage: "info.circle")
        }
    }
}

#Preview {
    Form {
        OpenStreetMapContributionNotice()
    }
}
