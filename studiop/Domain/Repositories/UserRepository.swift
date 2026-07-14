import Foundation

/// Mirrors `/users/info` and `/users/change/*` in docs/api-reference.md. The `?token=` query
/// parameter on `/users/info` is a NetworkClient/Core concern (every request carries it
/// automatically) — it does not appear in this Domain-level signature.
protocol UserRepository: Sendable {
    func fetchUserInfo() async throws -> User

    func changePassword(currentPassword: String, newPassword: String) async throws

    func changeUserInfo(_ user: User) async throws -> User

    func changeUserProfile(
        name: String?,
        phone: String?,
        email: String?,
        companyName: String?,
        taxCode: String?,
        socialProvider: String?
    ) async throws -> User

    func changeUserAddress(mainAddress: Address, shippingAddress: Address?) async throws

    func requestAccountRemoval(reason: String) async throws

    func confirmAccountRemoval(email: String, code: String) async throws
}
