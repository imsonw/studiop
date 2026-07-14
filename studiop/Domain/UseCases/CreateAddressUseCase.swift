import Foundation

struct CreateAddressUseCase {
    let repository: AddressRepository

    init(repository: AddressRepository) {
        self.repository = repository
    }

    func callAsFunction(_ address: Address) async throws -> Address {
        try await repository.createAddress(address)
    }
}
