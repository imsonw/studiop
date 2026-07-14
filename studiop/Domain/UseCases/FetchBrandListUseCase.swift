import Foundation

struct FetchBrandListUseCase {
    let repository: StoreRepository

    init(repository: StoreRepository) {
        self.repository = repository
    }

    func callAsFunction() async throws -> [Brand] {
        try await repository.fetchBrandList()
    }
}
