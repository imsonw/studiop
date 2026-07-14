import Foundation

struct FetchStoreFilterSettingsUseCase {
    let repository: StoreRepository

    init(repository: StoreRepository) {
        self.repository = repository
    }

    func callAsFunction(storeId: String) async throws -> StoreSettings {
        try await repository.fetchStoreFilterSettings(storeId: storeId)
    }
}
