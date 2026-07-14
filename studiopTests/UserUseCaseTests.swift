import Foundation
import Testing
@testable import studiop

private struct StubError: Error, Equatable {}

final class FakeUserRepository: UserRepository, @unchecked Sendable {
    var userToReturn = User(id: 1, idEncode: "abc", name: "Jane", email: "jane@example.com")
    var errorToThrow: Error?

    private(set) var fetchUserInfoCallCount = 0
    private(set) var lastChangePassword: (currentPassword: String, newPassword: String)?
    private(set) var lastChangeUserInfo: User?
    private(set) var lastChangeUserProfile: (name: String?, phone: String?, email: String?, companyName: String?, taxCode: String?, socialProvider: String?)?
    private(set) var lastChangeUserAddress: (mainAddress: Address, shippingAddress: Address?)?
    private(set) var lastRequestRemovalReason: String?
    private(set) var lastConfirmRemoval: (email: String, code: String)?

    func fetchUserInfo() async throws -> User {
        fetchUserInfoCallCount += 1
        if let errorToThrow { throw errorToThrow }
        return userToReturn
    }

    func changePassword(currentPassword: String, newPassword: String) async throws {
        lastChangePassword = (currentPassword, newPassword)
        if let errorToThrow { throw errorToThrow }
    }

    func changeUserInfo(_ user: User) async throws -> User {
        lastChangeUserInfo = user
        if let errorToThrow { throw errorToThrow }
        return userToReturn
    }

    func changeUserProfile(
        name: String?,
        phone: String?,
        email: String?,
        companyName: String?,
        taxCode: String?,
        socialProvider: String?
    ) async throws -> User {
        lastChangeUserProfile = (name, phone, email, companyName, taxCode, socialProvider)
        if let errorToThrow { throw errorToThrow }
        return userToReturn
    }

    func changeUserAddress(mainAddress: Address, shippingAddress: Address?) async throws {
        lastChangeUserAddress = (mainAddress, shippingAddress)
        if let errorToThrow { throw errorToThrow }
    }

    func requestAccountRemoval(reason: String) async throws {
        lastRequestRemovalReason = reason
        if let errorToThrow { throw errorToThrow }
    }

    func confirmAccountRemoval(email: String, code: String) async throws {
        lastConfirmRemoval = (email, code)
        if let errorToThrow { throw errorToThrow }
    }
}

struct UserUseCaseTests {
    @Test func fetchUserInfoReturnsUser() async throws {
        let fake = FakeUserRepository()
        let useCase = FetchUserInfoUseCase(repository: fake)

        let result = try await useCase()

        #expect(fake.fetchUserInfoCallCount == 1)
        #expect(result == fake.userToReturn)
    }

    @Test func fetchUserInfoPropagatesError() async throws {
        let fake = FakeUserRepository()
        fake.errorToThrow = StubError()
        let useCase = FetchUserInfoUseCase(repository: fake)

        await #expect(throws: StubError.self) {
            _ = try await useCase()
        }
    }

    @Test func changePasswordForwardsFields() async throws {
        let fake = FakeUserRepository()
        let useCase = ChangePasswordUseCase(repository: fake)

        try await useCase(currentPassword: "old", newPassword: "new")

        #expect(fake.lastChangePassword?.currentPassword == "old")
        #expect(fake.lastChangePassword?.newPassword == "new")
    }

    @Test func changeUserInfoForwardsUserAndReturnsResult() async throws {
        let fake = FakeUserRepository()
        let useCase = ChangeUserInfoUseCase(repository: fake)
        let updated = User(id: 1, idEncode: "abc", name: "Updated", email: "jane@example.com")

        let result = try await useCase(updated)

        #expect(fake.lastChangeUserInfo == updated)
        #expect(result == fake.userToReturn)
    }

    @Test func changeUserProfileForwardsPartialFields() async throws {
        let fake = FakeUserRepository()
        let useCase = ChangeUserProfileUseCase(repository: fake)

        _ = try await useCase(name: "New Name", companyName: "Acme")

        #expect(fake.lastChangeUserProfile?.name == "New Name")
        #expect(fake.lastChangeUserProfile?.companyName == "Acme")
        #expect(fake.lastChangeUserProfile?.phone == nil)
    }

    @Test func changeUserAddressForwardsMainAndShipping() async throws {
        let fake = FakeUserRepository()
        let useCase = ChangeUserAddressUseCase(repository: fake)
        let main = Address(fullName: "Jane", phone: "123", address: "St", houseNumber: "1", postalCode: "1000", location: "loc", country: "NL")

        try await useCase(mainAddress: main, shippingAddress: nil)

        #expect(fake.lastChangeUserAddress?.mainAddress == main)
        #expect(fake.lastChangeUserAddress?.shippingAddress == nil)
    }

    @Test func requestAccountRemovalForwardsReason() async throws {
        let fake = FakeUserRepository()
        let useCase = RequestAccountRemovalUseCase(repository: fake)

        try await useCase(reason: "no longer needed")

        #expect(fake.lastRequestRemovalReason == "no longer needed")
    }

    @Test func confirmAccountRemovalForwardsEmailAndCode() async throws {
        let fake = FakeUserRepository()
        let useCase = ConfirmAccountRemovalUseCase(repository: fake)

        try await useCase(email: "jane@example.com", code: "999")

        #expect(fake.lastConfirmRemoval?.email == "jane@example.com")
        #expect(fake.lastConfirmRemoval?.code == "999")
    }
}
