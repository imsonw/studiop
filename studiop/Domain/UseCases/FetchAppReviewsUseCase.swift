import Foundation

struct FetchAppReviewsUseCase {
    let repository: StaticContentRepository

    func callAsFunction() async throws -> [AppReview] {
        try await repository.fetchAppReviews()
    }
}
