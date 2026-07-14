import Foundation

struct FetchReviewWriteFormUseCase {
    let repository: ReviewRepository

    init(repository: ReviewRepository) {
        self.repository = repository
    }

    func callAsFunction(idEncode: String) async throws -> Review {
        try await repository.fetchReviewWriteForm(idEncode: idEncode)
    }
}
