import Foundation

struct ProcessCheckoutUseCase {
    let repository: StoreRepository

    init(repository: StoreRepository) {
        self.repository = repository
    }

    func callAsFunction(id: String, paymentMethod: String = "bank_transfer") async throws -> Order {
        try await repository.processCheckout(id: id, paymentMethod: paymentMethod)
    }
}
