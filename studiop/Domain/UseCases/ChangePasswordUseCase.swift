import Foundation

struct ChangePasswordUseCase {
    let repository: UserRepository

    init(repository: UserRepository) {
        self.repository = repository
    }

    func callAsFunction(currentPassword: String, newPassword: String) async throws {
        try await repository.changePassword(currentPassword: currentPassword, newPassword: newPassword)
    }
}
