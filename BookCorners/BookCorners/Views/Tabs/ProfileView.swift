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
                        Button("Login") {
                            showingLogin = true
                        }
                        Button("Register") {
                            showingRegister = true
                        }
                    }
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
    }
}

#Preview {
    ProfileView()
        .environment(AuthService(
            apiClient: APIClient(),
            keychainService: KeychainService(),
        ))
}
