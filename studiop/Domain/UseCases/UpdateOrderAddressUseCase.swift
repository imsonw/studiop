import Foundation

struct UpdateOrderAddressUseCase {
    let repository: OrderRepository

    init(repository: OrderRepository) {
        self.repository = repository
    }

    func callAsFunction(id: String, addressId: String) async throws -> Order {
        try await repository.updateOrderAddress(id: id, addressId: addressId)
    }
}
