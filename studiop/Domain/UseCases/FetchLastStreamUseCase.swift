import Foundation

struct FetchLastStreamUseCase {
    let repository: StreamRepository

    func callAsFunction() async throws -> LiveStreamSummary? {
        try await repository.fetchLastStream()
    }
}
