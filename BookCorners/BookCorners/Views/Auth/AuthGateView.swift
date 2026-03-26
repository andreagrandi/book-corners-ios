//
//  AuthGateView.swift
//  BookCorners
//

import SwiftUI

struct AuthGateView: View {
    enum AuthMode: String, CaseIterable {
        case login = "Login"
        case register = "Register"
    }

    @State private var authMode: AuthMode = .login
    @State private var username = ""
    @State private var password = ""
    @State private var email = ""
    @State private var confirmPassword = ""

    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                SocialLoginButtonsView()

                Section {
                    Picker("", selection: $authMode) {
                        ForEach(AuthMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                Section("Account") {
                    TextField("Username", text: $username)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    if authMode == .register {
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                    }

                    SecureField("Password", text: $password)
                        .textContentType(.password)

                    if authMode == .register {
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textContentType(.password)
                    }
                }

                if let error = authService.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                }

                if authMode == .register {
                    if !confirmPassword.isEmpty, password != confirmPassword {
                        Text("Passwords don't match")
                            .foregroundStyle(.red)
                    }

                    if !email.isEmpty, !email.contains("@") {
                        Text("Enter a valid email address")
                            .foregroundStyle(.red)
                    }
                }

                if authService.isLoading {
                    ProgressView()
                }

                Section {
                    Button(authMode == .login ? "Login" : "Register") {
                        let trimmedUsername = username.trimmingCharacters(in: .whitespaces)
                        Task {
                            if authMode == .login {
                                await authService.login(username: trimmedUsername, password: password)
                            } else {
                                let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
                                await authService.register(
                                    username: trimmedUsername,
                                    password: password,
                                    email: trimmedEmail,
                                )
                            }
                        }
                    }
                    .disabled(isSubmitDisabled)
                }
            }
            .navigationTitle(authMode == .login ? "Login" : "Register")
            .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated { dismiss() }
            }
            .onChange(of: authMode) { _, _ in
                authService.errorMessage = nil
            }
        }
    }

    private var isSubmitDisabled: Bool {
        if authService.isLoading { return true }
        if username.isEmpty || password.isEmpty { return true }
        if authMode == .register {
            return email.isEmpty || !email.contains("@") || confirmPassword.isEmpty || password != confirmPassword
        }
        return false
    }
}

#Preview {
    AuthGateView()
        .environment(AuthService(
            apiClient: APIClient(),
            keychainService: KeychainService(),
        ))
}
