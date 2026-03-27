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

    var body: some View {
        NavigationStack {
            List {
                if authService.isAuthenticated {
                    Section("Account") {
                        Text(authService.currentUser?.username ?? "Unknown")
                        Text(authService.currentUser?.email ?? "")
                    }
                    Section {
                        Button("Logout") {
                            authService.logout()
                        }
                    }
                } else {
                    Section {
                        Button("Sign In or Register") {
                            showingAuth = true
                        }
                    }
                }

                Section {
                    VStack(spacing: 12) {
                        Text("version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?").\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?")")
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

#Preview {
    ProfileView()
        .environment(AuthService(
            apiClient: APIClient(),
            keychainService: KeychainService(),
        ))
}
