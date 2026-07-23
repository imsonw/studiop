import Foundation

struct DeleteAddressUseCase {
    let repository: AddressRepository

    init(repository: AddressRepository) {
        self.repository = repository
    }

    func callAsFunction(id: Int) async throws {
        try await repository.deleteAddress(id: id)
    }
}
