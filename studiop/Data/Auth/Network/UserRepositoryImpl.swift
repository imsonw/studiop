import Foundation

/// Every method here needs the logged-in user's own token — `.userToken`, `NetworkRequest`'s
/// default, so it's never specified explicitly below.
final class UserRepositoryImpl: UserRepository {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    func fetchUserInfo() async throws -> User {
        let data = try await networkClient.send(NetworkRequest(path: "users/info"))
        return try JSONDecoder().decode(UserDTO.self, from: data).toDomain()
    }

    func changePassword(currentPassword: String, newPassword: String) async throws {
        let dto = ChangePasswordRequestDTO(currentPassword: currentPassword, newPassword: newPassword)
        _ = try await networkClient.send(
            NetworkRequest(path: "users/change/password", method: .post, body: try JSONEncoder().encode(dto))
        )
    }

    func changeUserInfo(_ user: User) async throws -> User {
        let dto = ChangeUserInfoRequestDTO(user: user)
        let data = try await networkClient.send(
            NetworkRequest(path: "users/change/info", method: .post, body: try JSONEncoder().encode(dto))
        )
        return try JSONDecoder().decode(UserDTO.self, from: data).toDomain()
    }

    func changeUserProfile(
        name: String?,
        phone: String?,
        email: String?,
        companyName: String?,
        taxCode: String?,
        socialProvider: String?
    ) async throws -> User {
        let dto = ChangeUserProfileRequestDTO(
            name: name,
            phone: phone,
            email: email,
            companyName: companyName,
            taxCode: taxCode,
            socialProvider: socialProvider
        )
        let data = try await networkClient.send(
            NetworkRequest(path: "users/change/profile", method: .post, body: try JSONEncoder().encode(dto))
        )
        return try JSONDecoder().decode(UserDTO.self, from: data).toDomain()
    }

    func changeUserAddress(mainAddress: Address, shippingAddress: Address?) async throws {
        let dto = ChangeUserAddressRequestDTO(
            mainAddress: AddressDTO(domain: mainAddress),
            shippingAddress: shippingAddress.map(AddressDTO.init(domain:))
        )
        _ = try await networkClient.send(
            NetworkRequest(path: "users/change/address", method: .post, body: try JSONEncoder().encode(dto))
        )
    }

    func requestAccountRemoval(reason: String) async throws {
        let dto = RequestAccountRemovalRequestDTO(reason: reason)
        _ = try await networkClient.send(
            NetworkRequest(path: "users/request_remove", method: .post, body: try JSONEncoder().encode(dto))
        )
    }

    func confirmAccountRemoval(email: String, code: String) async throws {
        let dto = ConfirmAccountRemovalRequestDTO(email: email, code: code)
        _ = try await networkClient.send(
            NetworkRequest(path: "users/request_remove/confirm", method: .post, body: try JSONEncoder().encode(dto))
        )
    }
}
