import Foundation

struct ChangeUserInfoUseCase {
    let repository: UserRepository

    init(repository: UserRepository) {
        self.repository = repository
    }

    func callAsFunction(_ user: User) async throws -> User {
        try await repository.changeUserInfo(user)
    }
}
