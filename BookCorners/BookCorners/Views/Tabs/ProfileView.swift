//
//  ProfileView.swift
//  BookCorners
//
//  Created by Andrea Grandi on 13/03/26.
//

import SwiftUI

struct ProfileView: View {
    @Environment(AuthService.self) private var authService

    @State private var showingLogin = false
    @State private var showingRegister = false
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
                    Section {
                        Button("Delete Account", role: .destructive) {
                            deleteConfirmationText = ""
                            showingDeleteConfirmation = true
                        }
                    }
                } else {
                    Section {
                        Button("Login") {
                            showingLogin = true
                        }
                        Button("Register") {
                            showingRegister = true
                        }
                    }

                    SocialLoginButtonsView()
                }

                Section {
                    HStack {
                        Spacer()
                        Text("version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?").\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?")")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("Profile")
        }
        .sheet(isPresented: $showingLogin) {
            LoginView()
        }
        .sheet(isPresented: $showingRegister) {
            RegisterView()
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
