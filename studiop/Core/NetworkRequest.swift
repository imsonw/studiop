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

    /// How `body` should be encoded on the wire. Every endpoint so far has been JSON except
    /// `StoreRepository`'s checkout calls, documented as "FormData" (not JSON) in
    /// docs/api-reference.md — `.formURLEncoded` covers those (see `StoreRepositoryImpl`).
    enum BodyEncoding: Equatable {
        case json
        case formURLEncoded
    }

    var path: String
    var method: Method
    var queryItems: [URLQueryItem]
    var body: Data?
    var bodyEncoding: BodyEncoding
    var headers: [String: String]
    var authentication: Authentication

    init(
        path: String,
        method: Method = .get,
        queryItems: [URLQueryItem] = [],
        body: Data? = nil,
        bodyEncoding: BodyEncoding = .json,
        headers: [String: String] = [:],
        authentication: Authentication = .userToken
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.body = body
        self.bodyEncoding = bodyEncoding
        self.headers = headers
        self.authentication = authentication
    }

    /// Encodes key/value pairs as an `application/x-www-form-urlencoded` body, for use with
    /// `bodyEncoding: .formURLEncoded`.
    static func formURLEncodedBody(_ fields: [String: String]) -> Data {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "+&=")
        let pairs = fields.map { key, value in
            "\(key)=\(value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value)"
        }
        return Data(pairs.joined(separator: "&").utf8)
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
