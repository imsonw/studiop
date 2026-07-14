import Foundation

struct GetCheckoutUseCase {
    let repository: StoreRepository

    init(repository: StoreRepository) {
        self.repository = repository
    }

    func callAsFunction(id: String, priceType: String) async throws -> CheckoutSession {
        try await repository.getCheckout(id: id, priceType: priceType)
    }
}
