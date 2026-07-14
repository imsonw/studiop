import Dependencies
import Foundation

protocol NetworkClient: Sendable {
    func send(_ request: NetworkRequest) async throws -> Data
}

/// URLSession-backed `NetworkClient`. Reproduces the Flutter app's auth mechanism exactly — see
/// docs/api-reference.md -> Auth mechanism:
/// - token travels as a `?token=` query param, never an `Authorization` header
/// - `lang` header and `device_fw` query param are attached to every request
/// - 401/403, or a 200 body reporting an invalid/expired/unauthorized token, clears the Keychain
///   token; there is no refresh-token endpoint, so no retry/refresh is attempted here
final class URLSessionNetworkClient: NetworkClient {
    /// Shared public token for anonymous/public endpoints — same value in both environments.
    private static let publicToken = "Xo0otTOevqxS4f6Vv1aGrcTfr6T5aUk5"
    /// `device_fw` platform code this app identifies itself as.
    private static let devicePlatformCode = "ios"

    private let session: URLSession
    private let environmentStore: EnvironmentStore
    private let keychainStore: KeychainStoring

    init(
        session: URLSession = .shared,
        environmentStore: EnvironmentStore,
        keychainStore: KeychainStoring
    ) {
        self.session = session
        self.environmentStore = environmentStore
        self.keychainStore = keychainStore
    }

    func send(_ request: NetworkRequest) async throws -> Data {
        let urlRequest = try makeURLRequest(for: request)
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw NetworkError.transport(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.transport("Non-HTTP response")
        }

        if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
            keychainStore.clear()
            throw NetworkError.sessionInvalidated
        }

        if httpResponse.statusCode == 200, containsInvalidTokenMessage(data) {
            keychainStore.clear()
            throw NetworkError.sessionInvalidated
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw NetworkError.http(status: httpResponse.statusCode, body: data)
        }

        return data
    }

    private func makeURLRequest(for request: NetworkRequest) throws -> URLRequest {
        let environment = environmentStore.current
        let endpointURL = environment.apiBaseURL.appendingPathComponent(request.path)

        guard var components = URLComponents(url: endpointURL, resolvingAgainstBaseURL: false) else {
            throw NetworkError.invalidURL
        }

        var queryItems = request.queryItems
        queryItems.append(URLQueryItem(name: "device_fw", value: Self.devicePlatformCode))
        queryItems.append(URLQueryItem(name: "token", value: token(for: request.authentication)))
        components.queryItems = (components.queryItems ?? []) + queryItems

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body
        urlRequest.setValue(currentLanguageCode(), forHTTPHeaderField: "lang")
        for (field, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: field)
        }
        return urlRequest
    }

    private func token(for authentication: NetworkRequest.Authentication) -> String {
        switch authentication {
        case .publicToken:
            return Self.publicToken
        case .userToken:
            return keychainStore.readToken() ?? Self.publicToken
        }
    }

    private func currentLanguageCode() -> String {
        Locale.current.language.languageCode?.identifier ?? "en"
    }

    /// Detects a `200 OK` body reporting an invalid/expired/unauthorized token.
    /// - Note: api-reference.md documents this behavior but not the literal response shape —
    ///   confirm the exact field/message with the backend team and tighten this check once known.
    private func containsInvalidTokenMessage(_ data: Data) -> Bool {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return false
        }
        let haystacks = ["message", "error", "msg"]
            .compactMap { json[$0] as? String }
            .map { $0.lowercased() }
        let invalidityKeywords = ["invalid", "expired", "unauthorized", "unauthenticated"]
        return haystacks.contains { haystack in
            haystack.contains("token") && invalidityKeywords.contains { haystack.contains($0) }
        }
    }
}

/// Fails loudly if a test exercises the network without overriding this dependency.
private struct UnimplementedNetworkClient: NetworkClient {
    func send(_ request: NetworkRequest) async throws -> Data {
        throw NetworkError.transport("NetworkClient.testValue was not overridden for this test")
    }
}

/// Returns empty data for every call — good enough for SwiftUI previews.
private struct PreviewNetworkClient: NetworkClient {
    func send(_ request: NetworkRequest) async throws -> Data {
        Data()
    }
}

private enum NetworkClientKey: DependencyKey {
    static var liveValue: NetworkClient {
        @Dependency(\.environmentStore) var environmentStore
        @Dependency(\.keychainStore) var keychainStore
        return URLSessionNetworkClient(environmentStore: environmentStore, keychainStore: keychainStore)
    }

    static let testValue: NetworkClient = UnimplementedNetworkClient()
    static let previewValue: NetworkClient = PreviewNetworkClient()
}

extension DependencyValues {
    var networkClient: NetworkClient {
        get { self[NetworkClientKey.self] }
        set { self[NetworkClientKey.self] = newValue }
    }
}
