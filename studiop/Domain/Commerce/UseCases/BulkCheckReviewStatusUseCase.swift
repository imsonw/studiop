import Foundation

struct BulkCheckReviewStatusUseCase {
    let repository: ReviewRepository

    init(repository: ReviewRepository) {
        self.repository = repository
    }

    func callAsFunction(idEncodes: [String]) async throws -> [String: Bool] {
        try await repository.bulkCheckReviewStatus(idEncodes: idEncodes)
    }
}
