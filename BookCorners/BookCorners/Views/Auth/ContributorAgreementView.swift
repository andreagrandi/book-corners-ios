//
//  ContributorAgreementView.swift
//  BookCorners
//

import SwiftUI
import WebKit

struct ContributorAgreementView: View {
    let url: URL

    var body: some View {
        WebView(url: url)
            .accessibilityIdentifier("contributor-agreement-web-view")
            .navigationTitle("Contributor Agreement")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ContributorAgreementView(url: ContributorAgreement.publishedURL)
}
