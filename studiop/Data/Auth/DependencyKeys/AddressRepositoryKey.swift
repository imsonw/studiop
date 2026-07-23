import Dependencies
import Foundation

private struct UnimplementedAddressRepository: AddressRepository {
    private struct Unimplemented: Error {}

    func listAddresses() async throws -> [Address] {
        throw Unimplemented()
    }

    func createAddress(_ address: Address) async throws -> Address {
        throw Unimplemented()
    }

    func updateAddress(id: Int, _ address: Address) async throws -> Address {
        throw Unimplemented()
    }

    func deleteAddress(id: Int) async throws {
        throw Unimplemented()
    }
}

private struct PreviewAddressRepository: AddressRepository {
    static let cannedAddresses: [Address] = [
        Address(
            id: 1,
            fullName: "Preview User",
            phone: "0123456789",
            address: "123 Preview Street",
            houseNumber: "1",
            postalCode: "700000",
            location: "Da Nang, Vietnam",
            country: "Vietnam",
            isDefault: true
        ),
    ]

    func listAddresses() async throws -> [Address] {
        Self.cannedAddresses
    }

    func createAddress(_ address: Address) async throws -> Address {
        address
    }

    func updateAddress(id: Int, _ address: Address) async throws -> Address {
        address
    }

    func deleteAddress(id: Int) async throws {}
}

private enum AddressRepositoryKey: DependencyKey {
    static var liveValue: AddressRepository {
        @Dependency(\.networkClient) var networkClient
        return AddressRepositoryImpl(networkClient: networkClient)
    }

    static let testValue: AddressRepository = UnimplementedAddressRepository()
    static let previewValue: AddressRepository = PreviewAddressRepository()
}

extension DependencyValues {
    var addressRepository: AddressRepository {
        get { self[AddressRepositoryKey.self] }
        set { self[AddressRepositoryKey.self] = newValue }
    }
}
