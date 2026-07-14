import Foundation

/// Describes a single call to the backend. `NetworkClient` fills in the parts that must be
/// present on every request (`token`, `lang`, `device_fw`) — callers only specify what's
/// specific to their endpoint.
struct NetworkRequest {
    enum Method: String {
        case get = "GET"
        case post = "POST"
        case delete = "DELETE"
    }

    /// Which token this request authenticates with — see docs/api-reference.md -> Auth mechanism.
    enum Authentication {
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
}
