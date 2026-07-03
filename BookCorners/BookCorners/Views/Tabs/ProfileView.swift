//
//  ProfileView.swift
//  BookCorners
//
//  Created by Andrea Grandi on 13/03/26.
//

import SwiftUI

struct ProfileView: View {
    @Environment(AuthService.self) private var authService

    @State private var showingAuth = false
    @State private var showingDeleteConfirmation = false
    @State private var deleteConfirmationText = ""

    private var appVersionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "version: \(version).\(build)"
    }

    var body: some View {
        NavigationStack {
            List {
                if authService.isAuthenticated {
                    Section("Account") {
                        Text(authService.currentUser?.username ?? "Unknown")
                        Text(authService.currentUser?.email ?? "")
                    }

                    Section("Contributions") {
                        NavigationLink {
                            ContributionCenterView()
                        } label: {
                            ContributionCenterProfileRow()
                        }
                        .accessibilityHint("Shows your submitted libraries, reports, photos, and favourites")
                    }

                    if authService.canAccessAdmin {
                        Section("Administration") {
                            NavigationLink {
                                AdminDashboardView()
                            } label: {
                                AdminDashboardProfileRow()
                            }
                            .accessibilityHint("Opens staff moderation tools")
                        }
                    }

                    Section {
                        Button("Logout") {
                            Task {
                                await authService.logout()
                            }
                        }
                    }
                } else {
                    Section {
                        Button("Sign In or Register") {
                            showingAuth = true
                        }
                    }
                }

                Section("About") {
                    Link(destination: URL(string: "https://www.andreagrandi.it")!) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.fill")
                                .frame(width: 20)
                            HStack(spacing: 0) {
                                Text("Made with ❤️ by ")
                                Text("Andrea Grandi")
                                    .bold()
                            }
                        }
                    }
                    .foregroundStyle(.primary)

                    Link(destination: URL(string: "https://www.bookcorners.org/privacy/")!) {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                    }
                    .foregroundStyle(.primary)

                    Link(destination: URL(string: "https://www.bookcorners.org")!) {
                        Label("Book Corners Website", systemImage: "globe")
                    }
                    .foregroundStyle(.primary)

                    Link(destination: URL(string: "https://github.com/andreagrandi/book-corners-ios")!) {
                        Label("Source Code on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                    .foregroundStyle(.primary)
                }

                Section("Socials") {
                    Link(destination: URL(string: "https://mastodon.social/@bookcorners")!) {
                        Label {
                            Text("Mastodon")
                        } icon: {
                            Image("MastodonIcon")
                                .renderingMode(.template)
                        }
                    }
                    .foregroundStyle(.primary)

                    Link(destination: URL(string: "https://bsky.app/profile/bookcorners.org")!) {
                        Label {
                            Text("Bluesky")
                        } icon: {
                            Image("BlueskyIcon")
                                .renderingMode(.template)
                        }
                    }
                    .foregroundStyle(.primary)

                    Link(destination: URL(string: "https://www.instagram.com/bookcornersorg/")!) {
                        Label {
                            Text("Instagram")
                        } icon: {
                            Image("InstagramIcon")
                                .renderingMode(.template)
                        }
                    }
                    .foregroundStyle(.primary)
                }

                Section {
                    VStack(spacing: 12) {
                        Text(appVersionText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        if authService.isAuthenticated {
                            Button("Delete Account") {
                                deleteConfirmationText = ""
                                showingDeleteConfirmation = true
                            }
                            .font(.footnote)
                            .foregroundStyle(.red.opacity(0.7))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("Profile")
        }
        .sheet(isPresented: $showingAuth) {
            AuthGateView()
        }
        .alert(
            "Delete Account",
            isPresented: $showingDeleteConfirmation,
        ) {
            if authService.currentUser?.isSocialOnly == true {
                TextField("Type DELETE to confirm", text: $deleteConfirmationText)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                Button("Delete", role: .destructive) {
                    Task {
                        await authService.deleteAccountSocial()
                    }
                }
                .disabled(deleteConfirmationText != "DELETE")
            } else {
                SecureField("Enter your password", text: $deleteConfirmationText)
                Button("Delete", role: .destructive) {
                    Task {
                        await authService.deleteAccount(password: deleteConfirmationText)
                    }
                }
                .disabled(deleteConfirmationText.isEmpty)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if authService.currentUser?.isSocialOnly == true {
                Text("This action is permanent. Type DELETE to confirm.")
            } else {
                Text("This action is permanent. Enter your password to confirm.")
            }
        }
    }
}

private struct ContributionCenterProfileRow: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "tray.full")
                .font(.headline)
                .foregroundStyle(.blue)
                .frame(width: 32, height: 32)
                .background(.blue.opacity(0.12), in: .rect(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("Contribution Center")
                    .foregroundStyle(.primary)

                Text("Track submissions and favourites")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Contribution Center, track submissions and favourites")
    }
}

private struct AdminDashboardProfileRow: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "rectangle.grid.2x2")
                .font(.headline)
                .foregroundStyle(.blue)
                .frame(width: 32, height: 32)
                .background(.blue.opacity(0.12), in: .rect(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("Admin Dashboard")
                    .foregroundStyle(.primary)

                Text("Review moderation queues")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("Staff")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.blue.opacity(0.12), in: Capsule())
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Admin Dashboard, staff moderation queues")
    }
}

#Preview {
    ProfileView()
        .environment(AuthService(
            apiClient: APIClient(),
            keychainService: KeychainService(),
        ))
}
