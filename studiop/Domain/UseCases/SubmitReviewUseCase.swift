import Foundation

struct SubmitReviewUseCase {
    let repository: ReviewRepository

    init(repository: ReviewRepository) {
        self.repository = repository
    }

    func callAsFunction(_ review: Review) async throws -> Review {
        try await repository.submitReview(review)
    }
}
