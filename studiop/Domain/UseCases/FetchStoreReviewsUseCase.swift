import Foundation

struct FetchStoreReviewsUseCase {
    let repository: ReviewRepository

    init(repository: ReviewRepository) {
        self.repository = repository
    }

    func callAsFunction(studioIdEncode: String, filter: String? = nil, page: Int? = nil) async throws -> [Review] {
        try await repository.fetchStoreReviews(studioIdEncode: studioIdEncode, filter: filter, page: page)
    }
}
