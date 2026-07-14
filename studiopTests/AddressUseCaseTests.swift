import Foundation
import Testing
@testable import studiop

private struct StubError: Error, Equatable {}

private func makeAddress(id: Int? = nil, isDefault: Bool = false) -> Address {
    Address(
        id: id,
        fullName: "Jane Doe",
        phone: "0123456789",
        address: "Main St",
        houseNumber: "42",
        postalCode: "1000AA",
        location: "Amsterdam",
        country: "NL",
        isDefault: isDefault
    )
}

final class FakeAddressRepository: AddressRepository, @unchecked Sendable {
    var addressesToReturn: [Address] = [makeAddress(id: 1)]
    var addressToReturn: Address = makeAddress(id: 1)
    var errorToThrow: Error?

    private(set) var listCallCount = 0
    private(set) var lastCreated: Address?
    private(set) var lastUpdated: (id: Int, address: Address)?
    private(set) var lastDeletedID: Int?

    func listAddresses() async throws -> [Address] {
        listCallCount += 1
        if let errorToThrow { throw errorToThrow }
        return addressesToReturn
    }

    func createAddress(_ address: Address) async throws -> Address {
        lastCreated = address
        if let errorToThrow { throw errorToThrow }
        return addressToReturn
    }

    func updateAddress(id: Int, _ address: Address) async throws -> Address {
        lastUpdated = (id, address)
        if let errorToThrow { throw errorToThrow }
        return addressToReturn
    }

    func deleteAddress(id: Int) async throws {
        lastDeletedID = id
        if let errorToThrow { throw errorToThrow }
    }
}

struct AddressUseCaseTests {
    @Test func listAddressesReturnsAll() async throws {
        let fake = FakeAddressRepository()
        let useCase = ListAddressesUseCase(repository: fake)

        let result = try await useCase()

        #expect(fake.listCallCount == 1)
        #expect(result == fake.addressesToReturn)
    }

    @Test func createAddressForwardsInputAndReturnsResult() async throws {
        let fake = FakeAddressRepository()
        let useCase = CreateAddressUseCase(repository: fake)
        let newAddress = makeAddress()

        let result = try await useCase(newAddress)

        #expect(fake.lastCreated == newAddress)
        #expect(result == fake.addressToReturn)
    }

    @Test func updateAddressForwardsIDAndAddress() async throws {
        let fake = FakeAddressRepository()
        let useCase = UpdateAddressUseCase(repository: fake)
        let updated = makeAddress(id: 1, isDefault: true)

        let result = try await useCase(id: 1, updated)

        #expect(fake.lastUpdated?.id == 1)
        #expect(fake.lastUpdated?.address == updated)
        #expect(result == fake.addressToReturn)
    }

    @Test func deleteAddressForwardsID() async throws {
        let fake = FakeAddressRepository()
        let useCase = DeleteAddressUseCase(repository: fake)

        try await useCase(id: 7)

        #expect(fake.lastDeletedID == 7)
    }

    @Test func deleteAddressPropagatesError() async throws {
        let fake = FakeAddressRepository()
        fake.errorToThrow = StubError()
        let useCase = DeleteAddressUseCase(repository: fake)

        await #expect(throws: StubError.self) {
            try await useCase(id: 7)
        }
    }
}
