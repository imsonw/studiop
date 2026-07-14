import Foundation

struct FetchProductReviewsUseCase {
    let repository: ReviewRepository

    init(repository: ReviewRepository) {
        self.repository = repository
    }

    func callAsFunction(productId: String, filter: String? = nil, page: Int? = nil) async throws -> [Review] {
        try await repository.fetchProductReviews(productId: productId, filter: filter, page: page)
    }
}
