import Foundation

/// Every method here needs the logged-in user's own token — `.userToken`, `NetworkRequest`'s
/// default — address book is account-scoped.
final class AddressRepositoryImpl: AddressRepository {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    func listAddresses() async throws -> [Address] {
        let data = try await networkClient.send(NetworkRequest(path: "users/address"))
        return try JSONDecoder().decode(DataResponseDTO<[AddressDTO]>.self, from: data).data.map { $0.toDomain() }
    }

    func createAddress(_ address: Address) async throws -> Address {
        let dto = AddressDTO(domain: address)
        let data = try await networkClient.send(
            NetworkRequest(path: "users/address/store", method: .post, body: try JSONEncoder().encode(dto))
        )
        return try JSONDecoder().decode(DataResponseDTO<AddressDTO>.self, from: data).data.toDomain()
    }

    func updateAddress(id: Int, _ address: Address) async throws -> Address {
        let dto = AddressDTO(domain: address)
        let data = try await networkClient.send(
            NetworkRequest(
                path: "users/address/update/\(id)",
                method: .post,
                body: try JSONEncoder().encode(dto)
            )
        )
        return try JSONDecoder().decode(DataResponseDTO<AddressDTO>.self, from: data).data.toDomain()
    }

    func deleteAddress(id: Int) async throws {
        _ = try await networkClient.send(NetworkRequest(path: "users/address/delete/\(id)", method: .post))
    }
}
