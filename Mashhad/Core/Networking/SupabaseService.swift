import Foundation

protocol SupabaseServiceProtocol: Sendable {
    var isConfigured: Bool { get }
    func healthCheck() async throws -> Bool
}

enum SupabaseError: LocalizedError, Sendable {
    case missingConfiguration

    var errorDescription: String? {
        switch self {
        case .missingConfiguration:
            return "أضف إعدادات Supabase لتفعيل المزامنة والحسابات."
        }
    }
}

final class SupabaseService: SupabaseServiceProtocol, @unchecked Sendable {
    private let baseURL: URL?
    private let anonKey: String?
    private let client: APIClient

    init(baseURL: URL?, anonKey: String?, client: APIClient = APIClient()) {
        self.baseURL = baseURL
        self.anonKey = anonKey
        self.client = client
    }

    var isConfigured: Bool { baseURL != nil && anonKey?.isEmpty == false }

    func healthCheck() async throws -> Bool {
        guard let baseURL, let anonKey, !anonKey.isEmpty else {
            throw SupabaseError.missingConfiguration
        }
        let _: EmptyResponse = try await client.get(
            baseURL: baseURL,
            path: "rest/v1/",
            headers: ["apikey": anonKey, "Authorization": "Bearer \(anonKey)"]
        )
        return true
    }
}

private struct EmptyResponse: Decodable {}
