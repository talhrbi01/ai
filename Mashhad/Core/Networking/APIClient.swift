import Foundation

enum APIClientError: LocalizedError, Sendable {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case decoding(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "The request URL is invalid."
        case .invalidResponse: return "The server returned an invalid response."
        case .httpStatus(let status): return "The server returned status \(status)."
        case .decoding(let message): return "The response could not be read: \(message)"
        }
    }
}

struct APIClient: Sendable {
    let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func get<T: Decodable>(
        baseURL: URL,
        path: String,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:]
    ) async throws -> T {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false) else {
            throw APIClientError.invalidURL
        }
        components.queryItems = queryItems
        guard let url = components.url else { throw APIClientError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw APIClientError.invalidResponse }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIClientError.httpStatus(httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIClientError.decoding(error.localizedDescription)
        }
    }

    func post<Body: Encodable, Response: Decodable>(
        baseURL: URL,
        path: String,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: Body
    ) async throws -> Response {
        let request = try makeRequest(
            baseURL: baseURL,
            path: path,
            method: "POST",
            queryItems: queryItems,
            headers: headers,
            body: body
        )
        return try await send(request)
    }

    func postNoContent<Body: Encodable>(
        baseURL: URL,
        path: String,
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: Body
    ) async throws {
        let request = try makeRequest(
            baseURL: baseURL,
            path: path,
            method: "POST",
            queryItems: queryItems,
            headers: headers,
            body: body
        )
        let (_, response) = try await session.data(for: request)
        try validate(response)
    }

    private func makeRequest<Body: Encodable>(
        baseURL: URL,
        path: String,
        method: String,
        queryItems: [URLQueryItem],
        headers: [String: String],
        body: Body
    ) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false) else {
            throw APIClientError.invalidURL
        }
        components.queryItems = queryItems
        guard let url = components.url else { throw APIClientError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        request.httpBody = try JSONEncoder().encode(body)
        return request
    }

    private func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        try validate(response)
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIClientError.decoding(error.localizedDescription)
        }
    }

    private func validate(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else { throw APIClientError.invalidResponse }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIClientError.httpStatus(httpResponse.statusCode)
        }
    }
}
