import Foundation
@testable import studiop

final class FakeNetworkClient: NetworkClient, @unchecked Sendable {
    var dataToReturn: Data = Data()
    var errorToThrow: Error?
    private(set) var receivedRequests: [NetworkRequest] = []

    var lastRequest: NetworkRequest? { receivedRequests.last }

    func send(_ request: NetworkRequest) async throws -> Data {
        receivedRequests.append(request)
        if let errorToThrow { throw errorToThrow }
        return dataToReturn
    }
}
