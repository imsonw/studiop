import Dependencies
import Foundation

private struct UnimplementedUserRepository: UserRepository {
    private struct Unimplemented: Error {}

    func fetchUserInfo() async throws -> User {
        throw Unimplemented()
    }

    func changePassword(currentPassword: String, newPassword: String) async throws {
        throw Unimplemented()
    }

    func changeUserInfo(_ user: User) async throws -> User {
        throw Unimplemented()
    }

    func changeUserProfile(
        name: String?,
        phone: String?,
        email: String?,
        companyName: String?,
        taxCode: String?,
        socialProvider: String?
    ) async throws -> User {
        throw Unimplemented()
    }

    func changeUserAddress(mainAddress: Address, shippingAddress: Address?) async throws {
        throw Unimplemented()
    }

    func requestAccountRemoval(reason: String) async throws {
        throw Unimplemented()
    }

    func confirmAccountRemoval(email: String, code: String) async throws {
        throw Unimplemented()
    }
}

private struct PreviewUserRepository: UserRepository {
    static let cannedUser = User(
        id: 1,
        idEncode: "preview-user",
        name: "Preview User",
        email: "preview@example.com"
    )

    func fetchUserInfo() async throws -> User {
        Self.cannedUser
    }

    func changePassword(currentPassword: String, newPassword: String) async throws {}

    func changeUserInfo(_ user: User) async throws -> User {
        user
    }

    func changeUserProfile(
        name: String?,
        phone: String?,
        email: String?,
        companyName: String?,
        taxCode: String?,
        socialProvider: String?
    ) async throws -> User {
        Self.cannedUser
    }

    func changeUserAddress(mainAddress: Address, shippingAddress: Address?) async throws {}

    func requestAccountRemoval(reason: String) async throws {}

    func confirmAccountRemoval(email: String, code: String) async throws {}
}

private enum UserRepositoryKey: DependencyKey {
    static var liveValue: UserRepository {
        @Dependency(\.networkClient) var networkClient
        return UserRepositoryImpl(networkClient: networkClient)
    }

    static let testValue: UserRepository = UnimplementedUserRepository()
    static let previewValue: UserRepository = PreviewUserRepository()
}

extension DependencyValues {
    var userRepository: UserRepository {
        get { self[UserRepositoryKey.self] }
        set { self[UserRepositoryKey.self] = newValue }
    }
}
