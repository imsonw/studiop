import Foundation
import Testing
@testable import studiop

private final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    static var requestHandler: (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: NetworkError.transport("no handler configured"))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private func makeSUT(keychainStore: KeychainStoring = InMemoryKeychainStore()) -> URLSessionNetworkClient {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    let session = URLSession(configuration: configuration)
    let environmentStore = EnvironmentStore(initial: .staging)
    return URLSessionNetworkClient(session: session, environmentStore: environmentStore, keychainStore: keychainStore)
}

private func jsonResponse(statusCode: Int, body: [String: Any] = [:]) -> (HTTPURLResponse, Data) {
    (
        HTTPURLResponse(url: URL(string: "https://staging.example/api/x")!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!,
        try! JSONSerialization.data(withJSONObject: body)
    )
}

// Serialized: tests share `MockURLProtocol.requestHandler`, a single mutable static — running
// them concurrently (Swift Testing's default) is a data race.
@Suite(.serialized)
struct NetworkClientTests {
    @Test func everyRequestAppendsTokenAsAQueryParamNeverAsAHeader() async throws {
        let keychainStore = InMemoryKeychainStore()
        keychainStore.writeToken("user-token")
        let sut = makeSUT(keychainStore: keychainStore)

        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            return jsonResponse(statusCode: 200)
        }

        _ = try await sut.send(NetworkRequest(path: "users/info", authentication: .userToken))

        let query = capturedRequest?.url?.query ?? ""
        #expect(query.contains("token=user-token"))
        #expect(capturedRequest?.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test func publicEndpointsUseTheSharedPublicToken() async throws {
        let sut = makeSUT()

        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            return jsonResponse(statusCode: 200)
        }

        _ = try await sut.send(NetworkRequest(path: "static/app_slides", authentication: .publicToken))

        #expect(capturedRequest?.url?.query?.contains("token=Xo0otTOevqxS4f6Vv1aGrcTfr6T5aUk5") == true)
    }

    @Test func everyRequestSendsLangHeaderAndDeviceFwQueryParam() async throws {
        let sut = makeSUT()

        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            return jsonResponse(statusCode: 200)
        }

        _ = try await sut.send(NetworkRequest(path: "users/info"))

        #expect(capturedRequest?.value(forHTTPHeaderField: "lang") != nil)
        #expect(capturedRequest?.url?.query?.contains("device_fw=ios") == true)
    }

    @Test func status401ClearsTheKeychainTokenAndThrowsSessionInvalidated() async throws {
        let keychainStore = InMemoryKeychainStore()
        keychainStore.writeToken("user-token")
        let sut = makeSUT(keychainStore: keychainStore)

        MockURLProtocol.requestHandler = { _ in jsonResponse(statusCode: 401) }

        await #expect(throws: NetworkError.self) {
            _ = try await sut.send(NetworkRequest(path: "users/info"))
        }
        #expect(keychainStore.readToken() == nil)
    }

    @Test func status403ClearsTheKeychainTokenAndThrowsSessionInvalidated() async throws {
        let keychainStore = InMemoryKeychainStore()
        keychainStore.writeToken("user-token")
        let sut = makeSUT(keychainStore: keychainStore)

        MockURLProtocol.requestHandler = { _ in jsonResponse(statusCode: 403) }

        await #expect(throws: NetworkError.self) {
            _ = try await sut.send(NetworkRequest(path: "users/info"))
        }
        #expect(keychainStore.readToken() == nil)
    }

    @Test func invalidTokenMessageIn200BodyClearsTheKeychainTokenAndNeverCallsRefresh() async throws {
        let keychainStore = InMemoryKeychainStore()
        keychainStore.writeToken("user-token")
        let sut = makeSUT(keychainStore: keychainStore)

        MockURLProtocol.requestHandler = { _ in
            jsonResponse(statusCode: 200, body: ["message": "Unauthorized: token expired"])
        }

        await #expect(throws: NetworkError.self) {
            _ = try await sut.send(NetworkRequest(path: "users/info"))
        }
        #expect(keychainStore.readToken() == nil)
    }

    @Test func requestsWithABodySetJSONContentType() async throws {
        let sut = makeSUT()

        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            return jsonResponse(statusCode: 200)
        }

        _ = try await sut.send(NetworkRequest(
            path: "users/login",
            method: .post,
            body: try JSONEncoder().encode(["email": "a@b.com"]),
            authentication: .publicToken
        ))

        #expect(capturedRequest?.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test func requestsWithoutABodyDoNotSetContentType() async throws {
        let sut = makeSUT()

        var capturedRequest: URLRequest?
        MockURLProtocol.requestHandler = { request in
            capturedRequest = request
            return jsonResponse(statusCode: 200)
        }

        _ = try await sut.send(NetworkRequest(path: "users/info"))

        #expect(capturedRequest?.value(forHTTPHeaderField: "Content-Type") == nil)
    }

    @Test func status0On200ThrowsAPIErrorWithTheBackendsOwnMessage() async throws {
        let sut = makeSUT()
        // Real captured failure shape: HTTP 200, business failure signaled via status/msg.
        MockURLProtocol.requestHandler = { _ in
            jsonResponse(statusCode: 200, body: ["status": 0, "msg": "Please enter your Email."])
        }

        await #expect(throws: NetworkError.self) {
            _ = try await sut.send(NetworkRequest(path: "users/login", method: .post, authentication: .publicToken))
        }
    }

    @Test func apiErrorMessageSurfacesTheBackendsOwnText() async throws {
        let error = NetworkError.apiError(message: "Please enter your Email.")
        #expect(error.localizedDescription == "Please enter your Email.")
    }

    @Test func aNormalSuccessfulResponseIsReturnedAsIs() async throws {
        let sut = makeSUT()
        MockURLProtocol.requestHandler = { _ in jsonResponse(statusCode: 200, body: ["ok": true]) }

        let data = try await sut.send(NetworkRequest(path: "users/info"))

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        #expect(json?["ok"] as? Bool == true)
    }
}
