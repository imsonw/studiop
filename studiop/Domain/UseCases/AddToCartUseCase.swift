import Foundation

struct AddToCartUseCase {
    let repository: StoreRepository

    init(repository: StoreRepository) {
        self.repository = repository
    }

    func callAsFunction(productId: String, quantity: Int, priceType: String) async throws -> CartItem {
        try await repository.addToCart(productId: productId, quantity: quantity, priceType: priceType)
    }
}
