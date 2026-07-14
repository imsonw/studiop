import Foundation

struct FetchHomepageZonesUseCase {
    let repository: StoreRepository

    init(repository: StoreRepository) {
        self.repository = repository
    }

    func callAsFunction(storeId: String) async throws -> StoreSettings {
        try await repository.fetchHomepageZones(storeId: storeId)
    }
}
