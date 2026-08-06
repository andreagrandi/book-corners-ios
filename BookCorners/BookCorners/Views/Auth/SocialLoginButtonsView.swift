//
//  SocialLoginButtonsView.swift
//  BookCorners
//

import AuthenticationServices
import GoogleSignIn
import SwiftUI

struct SocialLoginButtonsView: View {
    let isRegistration: Bool
    let hasAcceptedContributorAgreement: Bool

    @Environment(AuthService.self) private var authService

    var body: some View {
        Section {
            SignInWithAppleButton(isRegistration ? .signUp : .signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                handleAppleSignIn(result)
            }
            .frame(height: 44)
            .disabled(isDisabled)
            .accessibilityIdentifier("social-apple-button")
            .accessibilityLabel(isRegistration ? "Sign up with Apple" : "Sign in with Apple")
            .accessibilityHint(accessibilityHint)

            Button(action: handleGoogleSignIn) {
                HStack {
                    Image("GoogleLogo")
                        .resizable()
                        .frame(width: 18, height: 18)
                    Text(isRegistration ? "Sign up with Google" : "Sign in with Google")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.primary.opacity(0.2), lineWidth: 1),
                )
            }
            .buttonStyle(.plain)
            .disabled(isDisabled)
            .accessibilityIdentifier("social-google-button")
            .accessibilityHint(accessibilityHint)
        }
    }

    private var contributorAgreement: ContributorAgreement.Acceptance? {
        guard isRegistration, hasAcceptedContributorAgreement else {
            return nil
        }
        return ContributorAgreement.currentAcceptance
    }

    private var isDisabled: Bool {
        authService.isLoading || (isRegistration && !hasAcceptedContributorAgreement)
    }

    private var accessibilityHint: String {
        if isRegistration, !hasAcceptedContributorAgreement {
            return "Accept the Contributor Agreement before creating an account"
        }
        return isRegistration ? "Creates an account using this provider" : "Logs in to an existing account"
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, any Error>) {
        switch result {
        case let .success(auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let identityToken = String(data: tokenData, encoding: .utf8)
            else { return }
            let firstName = credential.fullName?.givenName
            let lastName = credential.fullName?.familyName
            Task {
                await authService.loginWithApple(
                    identityToken: identityToken,
                    firstName: firstName,
                    lastName: lastName,
                    contributorAgreement: contributorAgreement,
                )
            }
        case let .failure(error):
            if (error as? ASAuthorizationError)?.code == .canceled {
                return
            }
            authService.errorMessage = error.localizedDescription
        }
    }

    private func handleGoogleSignIn() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController
        else { return }
        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { result, error in
            if let error {
                if (error as NSError).code == GIDSignInError.canceled.rawValue {
                    return
                }
                authService.errorMessage = error.localizedDescription
                return
            }
            guard let idToken = result?.user.idToken?.tokenString else { return }
            Task {
                await authService.loginWithGoogle(
                    idToken: idToken,
                    contributorAgreement: contributorAgreement,
                )
            }
        }
    }
}
