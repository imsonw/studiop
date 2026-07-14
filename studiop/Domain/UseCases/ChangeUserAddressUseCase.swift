import Foundation

struct ChangeUserAddressUseCase {
    let repository: UserRepository

    init(repository: UserRepository) {
        self.repository = repository
    }

    func callAsFunction(mainAddress: Address, shippingAddress: Address? = nil) async throws {
        try await repository.changeUserAddress(mainAddress: mainAddress, shippingAddress: shippingAddress)
    }
}
