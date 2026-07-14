import Foundation

struct FetchStoreReviewStatsUseCase {
    let repository: ReviewRepository

    init(repository: ReviewRepository) {
        self.repository = repository
    }

    func callAsFunction(studioIdEncode: String) async throws -> ReviewStoreStats {
        try await repository.fetchStoreReviewStats(studioIdEncode: studioIdEncode)
    }
}
