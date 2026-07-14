import Foundation

struct BuyNowUseCase {
    let repository: StoreRepository

    init(repository: StoreRepository) {
        self.repository = repository
    }

    func callAsFunction(productId: String, quantity: Int, priceType: String) async throws -> CheckoutSession {
        try await repository.buyNow(productId: productId, quantity: quantity, priceType: priceType)
    }
}
