import Foundation

struct ClearCartUseCase {
    let repository: StoreRepository

    init(repository: StoreRepository) {
        self.repository = repository
    }

    func callAsFunction() async throws {
        try await repository.clearCart()
    }
}
