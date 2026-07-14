import Foundation

struct FetchStreamSellingLogUseCase {
    let repository: StreamRepository

    func callAsFunction(id: String, sort: String = "desc") async throws -> StreamSellingLog? {
        try await repository.fetchStreamSellingLog(id: id, sort: sort)
    }
}
