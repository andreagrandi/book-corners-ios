//
//  ContributorAgreementSection.swift
//  BookCorners
//

import SwiftUI

struct ContributorAgreementSection: View {
    @Binding var isAccepted: Bool

    var body: some View {
        Section("Contributor Agreement") {
            Text("The agreement lets Book Corners use and share the data and images you contribute. It applies to your contributions, not your account details.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button {
                isAccepted.toggle()
            } label: {
                Label {
                    Text("I have read and accept Contributor Agreement v\(ContributorAgreement.currentVersion)")
                } icon: {
                    Image(systemName: isAccepted ? "checkmark.square.fill" : "square")
                        .foregroundStyle(isAccepted ? .blue : .secondary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("contributor-agreement-acceptance")
            .accessibilityValue(isAccepted ? "Accepted" : "Not accepted")
            .accessibilityHint("Required to create an account")
            .accessibilityAddTraits(isAccepted ? .isSelected : [])

            NavigationLink {
                ContributorAgreementView(url: ContributorAgreement.presentationURL)
            } label: {
                Text("Read Contributor Agreement v\(ContributorAgreement.currentVersion)")
            }
            .accessibilityIdentifier("read-contributor-agreement")
            .accessibilityHint("Opens the full agreement before you accept it")
        }
    }
}

#Preview {
    @Previewable @State var isAccepted = false

    Form {
        ContributorAgreementSection(isAccepted: $isAccepted)
    }
}
