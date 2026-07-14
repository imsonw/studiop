import Foundation

struct UpdateAddressUseCase {
    let repository: AddressRepository

    init(repository: AddressRepository) {
        self.repository = repository
    }

    func callAsFunction(id: Int, _ address: Address) async throws -> Address {
        try await repository.updateAddress(id: id, address)
    }
}
