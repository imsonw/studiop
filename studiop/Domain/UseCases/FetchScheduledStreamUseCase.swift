import Foundation

struct FetchScheduledStreamUseCase {
    let repository: StreamRepository

    func callAsFunction(id: String) async throws -> ScheduledStream {
        try await repository.fetchScheduledStream(id: id)
    }
}
