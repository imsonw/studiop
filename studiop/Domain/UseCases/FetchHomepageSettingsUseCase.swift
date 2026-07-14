import Foundation

struct FetchHomepageSettingsUseCase {
    let repository: StoreRepository

    init(repository: StoreRepository) {
        self.repository = repository
    }

    func callAsFunction() async throws -> StoreSettings {
        try await repository.fetchHomepageSettings()
    }
}
