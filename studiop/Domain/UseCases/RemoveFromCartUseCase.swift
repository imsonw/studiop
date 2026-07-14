import Foundation

struct RemoveFromCartUseCase {
    let repository: StoreRepository

    init(repository: StoreRepository) {
        self.repository = repository
    }

    func callAsFunction(productId: String) async throws {
        try await repository.removeFromCart(productId: productId)
    }
}
