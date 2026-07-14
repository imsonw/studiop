import Foundation

struct CountCartUseCase {
    let repository: StoreRepository

    init(repository: StoreRepository) {
        self.repository = repository
    }

    func callAsFunction() async throws -> Int {
        try await repository.countCart()
    }
}
