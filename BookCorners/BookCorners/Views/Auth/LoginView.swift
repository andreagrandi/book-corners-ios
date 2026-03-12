//
//  LoginView.swift
//  BookCorners
//
//  Created by Andrea Grandi on 12/03/26.
//

import SwiftUI

struct LoginView: View {
    @State private var username = ""
    @State private var password = ""

    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    TextField("Username", text: $username)
                        .textContentType(.username)
                        .autocorrectionDisabled()
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                }

                if let error = authService.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                }

                if authService.isLoading {
                    ProgressView()
                }

                Section {
                    Button("Login") {
                        Task { await authService.login(username: username, password: password) }
                    }
                    .disabled(username.isEmpty || password.isEmpty || authService.isLoading)
                }
            }
            .navigationTitle("Login")
            .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated { dismiss() }
            }
        }
    }
}

#Preview {
    LoginView()
        .environment(AuthService(
            apiClient: APIClient(),
            keychainService: KeychainService(),
        ))
}
