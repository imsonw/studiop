import Foundation

struct FetchLiveStreamListUseCase {
    let repository: StreamRepository

    func callAsFunction(type: String? = nil, idEncode: String? = nil) async throws -> [LiveStreamSummary] {
        try await repository.fetchLiveStreamList(type: type, idEncode: idEncode)
    }
}
