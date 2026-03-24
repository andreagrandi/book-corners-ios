//
//  RegisterView.swift
//  BookCorners
//
//  Created by Andrea Grandi on 13/03/26.
//

import SwiftUI

struct RegisterView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var email = ""
    @State private var confirmPassword = ""

    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    TextField("Username", text: $username)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textContentType(.password)
                }

                if let error = authService.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                }

                if !confirmPassword.isEmpty, password != confirmPassword {
                    Text("Passwords don't match")
                        .foregroundStyle(.red)
                }

                if !email.isEmpty, !email.contains("@") {
                    Text("Enter a valid email address")
                        .foregroundStyle(.red)
                }

                if authService.isLoading {
                    ProgressView()
                }

                Section {
                    Button("Register") {
                        let trimmedUsername = username.trimmingCharacters(in: .whitespaces)
                        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
                        Task { await authService.register(username: trimmedUsername, password: password, email: trimmedEmail) }
                    }
                    .disabled(username.isEmpty || email.isEmpty || !email.contains("@") || password.isEmpty || confirmPassword.isEmpty || password != confirmPassword ||
                        authService.isLoading)
                }

                Button("Already have an account? Login") { dismiss() }
            }
            .navigationTitle("Register")
            .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated { dismiss() }
            }
        }
    }
}

#Preview {
    RegisterView()
        .environment(AuthService(
            apiClient: APIClient(),
            keychainService: KeychainService(),
        ))
}
