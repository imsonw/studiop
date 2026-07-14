import Foundation

/// Mirrors `/users/address/*` in docs/api-reference.md: list, create (`store`), update, delete.
protocol AddressRepository: Sendable {
    func listAddresses() async throws -> [Address]

    func createAddress(_ address: Address) async throws -> Address

    func updateAddress(id: Int, _ address: Address) async throws -> Address

    func deleteAddress(id: Int) async throws
}
