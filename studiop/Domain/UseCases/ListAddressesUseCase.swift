import Foundation

struct ListAddressesUseCase {
    let repository: AddressRepository

    init(repository: AddressRepository) {
        self.repository = repository
    }

    func callAsFunction() async throws -> [Address] {
        try await repository.listAddresses()
    }
}
