import Foundation

struct UpdateCheckoutAddressUseCase {
    let repository: StoreRepository

    init(repository: StoreRepository) {
        self.repository = repository
    }

    func callAsFunction(id: String, addressId: String) async throws -> CheckoutSession {
        try await repository.updateCheckoutAddress(id: id, addressId: addressId)
    }
}
