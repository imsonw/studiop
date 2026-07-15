import Foundation

/// Describes a single call to the backend. `NetworkClient` fills in the parts that must be
/// present on every request (`token`, `lang`, `device_fw`) — callers only specify what's
/// specific to their endpoint.
struct NetworkRequest {
    enum Method: String, Equatable {
        case get = "GET"
        case post = "POST"
        case delete = "DELETE"
    }

    /// Which token this request authenticates with — see docs/api-reference.md -> Auth mechanism.
    enum Authentication: Equatable {
        case publicToken
        case userToken
    }

    var path: String
    var method: Method
    var queryItems: [URLQueryItem]
    var body: Data?
    var headers: [String: String]
    var authentication: Authentication

    init(
        path: String,
        method: Method = .get,
        queryItems: [URLQueryItem] = [],
        body: Data? = nil,
        headers: [String: String] = [:],
        authentication: Authentication = .userToken
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.body = body
        self.headers = headers
        self.authentication = authentication
    }
}

enum NetworkError: Error {
    case invalidURL
    /// 401/403, or a 200 body reporting an invalid/expired/unauthorized token. The Keychain
    /// token has already been cleared by the time this is thrown — there is no refresh flow.
    case sessionInvalidated
    case http(status: Int, body: Data)
    case transport(String)
    /// This backend reports business failures via `{"status": 0, "msg": "..."}` on an otherwise
    /// `200 OK` response (confirmed against real captured traffic, e.g. login with a missing
    /// field) — not via the HTTP status code. `message` is the backend's own `msg`, safe to show
    /// directly to the user.
    case apiError(message: String)
}

extension NetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid request URL."
        case .sessionInvalidated:
            return "Your session has expired. Please log in again."
        case .http(let status, _):
            return "Server error (\(status))."
        case .transport(let message):
            return message
        case .apiError(let message):
            return message
        }
    }
}
