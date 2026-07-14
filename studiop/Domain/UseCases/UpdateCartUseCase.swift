import Foundation

struct UpdateCartUseCase {
    let repository: StoreRepository

    init(repository: StoreRepository) {
        self.repository = repository
    }

    func callAsFunction(productId: String, quantity: Int) async throws -> CartItem {
        try await repository.updateCart(productId: productId, quantity: quantity)
    }
}
