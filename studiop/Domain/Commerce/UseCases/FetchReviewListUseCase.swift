import Foundation

struct FetchReviewListUseCase {
    let repository: ReviewRepository

    init(repository: ReviewRepository) {
        self.repository = repository
    }

    func callAsFunction(status: String? = nil, page: Int? = nil) async throws -> [Review] {
        try await repository.fetchReviewList(status: status, page: page)
    }
}
