import Foundation

struct AuthSession: Codable, Sendable, Equatable {
    let accessToken: String
    let refreshToken: String?
    let userID: String?
    let expiresIn: Int?
}

protocol AuthenticationServiceProtocol: Sendable {
    func signIn(email: String, password: String) async throws -> AuthSession
    func signUp(email: String, password: String) async throws -> AuthSession?
    func signInWithApple(idToken: String, nonce: String?) async throws -> AuthSession
    func signOut(accessToken: String) async throws
    func deleteAccount(accessToken: String) async throws
}

enum AuthenticationError: LocalizedError, Sendable {
    case missingConfiguration
    case invalidInput
    case emailConfirmationRequired

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "أضف إعدادات Supabase لتفعيل الحسابات."
        case .invalidInput:
            return "تحقق من البريد وكلمة المرور ثم حاول مرة أخرى."
        case .emailConfirmationRequired:
            return "تحقق من بريدك الإلكتروني لإكمال إنشاء الحساب."
        }
    }
}

final class SupabaseAuthenticationService: AuthenticationServiceProtocol, @unchecked Sendable {
    private let baseURL: URL?
    private let anonKey: String?
    private let client: APIClient

    init(baseURL: URL?, anonKey: String?, client: APIClient = APIClient()) {
        self.baseURL = baseURL
        self.anonKey = anonKey
        self.client = client
    }

    func signIn(email: String, password: String) async throws -> AuthSession {
        guard let baseURL, let anonKey, !anonKey.isEmpty else { throw AuthenticationError.missingConfiguration }
        guard isValid(email: email), password.count >= 8 else { throw AuthenticationError.invalidInput }
        let response: SupabaseAuthResponse = try await client.post(
            baseURL: baseURL,
            path: "auth/v1/token",
            queryItems: [URLQueryItem(name: "grant_type", value: "password")],
            headers: ["apikey": anonKey],
            body: Credentials(email: email, password: password)
        )
        return response.session
    }

    func signUp(email: String, password: String) async throws -> AuthSession? {
        guard let baseURL, let anonKey, !anonKey.isEmpty else { throw AuthenticationError.missingConfiguration }
        guard isValid(email: email), password.count >= 8 else { throw AuthenticationError.invalidInput }
        let response: SupabaseAuthResponse = try await client.post(
            baseURL: baseURL,
            path: "auth/v1/signup",
            headers: ["apikey": anonKey],
            body: Credentials(email: email, password: password)
        )
        return response.accessToken == nil ? nil : response.session
    }

    func signInWithApple(idToken: String, nonce: String?) async throws -> AuthSession {
        guard let baseURL, let anonKey, !anonKey.isEmpty else { throw AuthenticationError.missingConfiguration }
        guard !idToken.isEmpty else { throw AuthenticationError.invalidInput }
        let response: SupabaseAuthResponse = try await client.post(
            baseURL: baseURL,
            path: "auth/v1/token",
            queryItems: [URLQueryItem(name: "grant_type", value: "id_token")],
            headers: ["apikey": anonKey],
            body: AppleCredentials(provider: "apple", idToken: idToken, nonce: nonce)
        )
        return response.session
    }

    func signOut(accessToken: String) async throws {
        guard let baseURL, let anonKey, !anonKey.isEmpty else { throw AuthenticationError.missingConfiguration }
        try await client.postNoContent(
            baseURL: baseURL,
            path: "auth/v1/logout",
            headers: ["apikey": anonKey, "Authorization": "Bearer \(accessToken)"],
            body: EmptyBody()
        )
    }

    func deleteAccount(accessToken: String) async throws {
        guard let baseURL, let anonKey, !anonKey.isEmpty else { throw AuthenticationError.missingConfiguration }
        try await client.postNoContent(
            baseURL: baseURL,
            path: "functions/v1/delete-account",
            headers: ["apikey": anonKey, "Authorization": "Bearer \(accessToken)"],
            body: EmptyBody()
        )
    }

    private func isValid(email: String) -> Bool {
        email.contains("@") && email.contains(".")
    }
}

private struct Credentials: Encodable {
    let email: String
    let password: String
}

private struct AppleCredentials: Encodable {
    let provider: String
    let idToken: String
    let nonce: String?

    enum CodingKeys: String, CodingKey {
        case provider
        case idToken = "id_token"
        case nonce
    }
}

private struct EmptyBody: Encodable {}

private struct SupabaseAuthResponse: Decodable {
    let accessToken: String?
    let refreshToken: String?
    let expiresIn: Int?
    let user: SupabaseUser?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case user
    }

    var session: AuthSession {
        AuthSession(accessToken: accessToken ?? "", refreshToken: refreshToken, userID: user?.id, expiresIn: expiresIn)
    }
}

private struct SupabaseUser: Decodable {
    let id: String
}
