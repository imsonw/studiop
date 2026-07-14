import Foundation

struct FetchStoreDetailUseCase {
    let repository: StoreRepository

    init(repository: StoreRepository) {
        self.repository = repository
    }

    func callAsFunction(id: String) async throws -> StoreSettings {
        try await repository.fetchStoreDetail(id: id)
    }
}
