import Foundation

struct CreateCheckoutUseCase {
    let repository: StoreRepository

    init(repository: StoreRepository) {
        self.repository = repository
    }

    func callAsFunction(itemIds: [String]) async throws -> CheckoutSession {
        try await repository.createCheckout(itemIds: itemIds)
    }
}
