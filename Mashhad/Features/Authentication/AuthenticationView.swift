import AuthenticationServices
import CryptoKit
import SwiftUI

struct AuthenticationView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.dismiss) private var dismiss
    @State private var mode: AuthMode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var confirmation = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    @State private var appleNonce: String?

    var body: some View {
        MashhadBackground {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("auth_title")
                            .font(.largeTitle.bold())
                            .foregroundStyle(MashhadTheme.textPrimary)
                        Text(LocalizedStringKey(mode == .signIn ? "auth_sign_in_message" : "auth_sign_up_message"))
                            .font(.subheadline)
                            .foregroundStyle(MashhadTheme.textSecondary)
                    }

                    Picker("auth_mode", selection: $mode) {
                        Text("auth_sign_in").tag(AuthMode.signIn)
                        Text("auth_sign_up").tag(AuthMode.signUp)
                    }
                    .pickerStyle(.segmented)

                    VStack(spacing: 14) {
                        TextField("auth_email", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .textFieldStyle(.roundedBorder)
                        SecureField("auth_password", text: $password)
                            .textContentType(mode == .signIn ? .password : .newPassword)
                            .textFieldStyle(.roundedBorder)
                        if mode == .signUp {
                            SecureField("auth_confirm_password", text: $confirmation)
                                .textContentType(.newPassword)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .accessibilityAddTraits(.isStaticText)
                    }
                    if let successMessage {
                        Text(successMessage)
                            .font(.footnote)
                            .foregroundStyle(MashhadTheme.accentSecondary)
                    }

                    Button {
                        Task { await submit() }
                    } label: {
                        Group {
                            if isSubmitting { ProgressView().tint(.white) }
                            else { Text(LocalizedStringKey(mode == .signIn ? "auth_sign_in_action" : "auth_sign_up_action")) }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(MashhadTheme.accent)
                    .controlSize(.large)
                    .disabled(isSubmitting)

                    SignInWithAppleButton(.signIn) { request in
                        let nonce = randomNonce()
                        appleNonce = nonce
                        request.requestedScopes = [.email, .fullName]
                        request.nonce = sha256(nonce)
                    } onCompletion: { result in
                        Task { await handleAppleResult(result) }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    Text("auth_privacy_note")
                        .font(.caption)
                        .foregroundStyle(MashhadTheme.textSecondary)
                }
                .padding(.horizontal, MashhadTheme.pagePadding)
                .padding(.vertical, 24)
            }
        }
        .navigationTitle("auth_title")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: mode) { _, _ in
            errorMessage = nil
            successMessage = nil
        }
    }

    @MainActor
    private func submit() async {
        errorMessage = nil
        successMessage = nil
        guard mode == .signIn || confirmation == password else {
            errorMessage = AuthenticationError.invalidInput.localizedDescription
            return
        }
        isSubmitting = true
        defer { isSubmitting = false }
        do {
            if mode == .signIn {
                let session = try await environment.authenticationService.signIn(email: email, password: password)
                environment.session.setAuthenticated(session)
                environment.session.completeAuthenticatedOnboarding()
                dismiss()
            } else if let session = try await environment.authenticationService.signUp(email: email, password: password) {
                environment.session.setAuthenticated(session)
                environment.session.completeAuthenticatedOnboarding()
                dismiss()
            } else {
                successMessage = AuthenticationError.emailConfirmationRequired.localizedDescription
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func handleAppleResult(_ result: Result<ASAuthorization, Error>) async {
        errorMessage = nil
        switch result {
        case .failure(let error):
            errorMessage = error.localizedDescription
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityToken = credential.identityToken,
                  let token = String(data: identityToken, encoding: .utf8),
                  let appleNonce else {
                errorMessage = AuthenticationError.invalidInput.localizedDescription
                return
            }
            isSubmitting = true
            defer { isSubmitting = false }
            do {
                let session = try await environment.authenticationService.signInWithApple(idToken: token, nonce: appleNonce)
                environment.session.setAuthenticated(session)
                environment.session.completeAuthenticatedOnboarding()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func randomNonce(length: Int = 32) -> String {
        let characters = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        while remainingLength > 0 {
            let randomBytes = (0..<16).map { _ in UInt8.random(in: 0...255) }
            randomBytes.forEach { byte in
                guard remainingLength > 0 else { return }
                if byte < characters.count {
                    result.append(characters[Int(byte)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}

private enum AuthMode: String, CaseIterable, Hashable {
    case signIn
    case signUp
}
