import Foundation

struct FetchUserInfoUseCase {
    let repository: UserRepository

    init(repository: UserRepository) {
        self.repository = repository
    }

    func callAsFunction() async throws -> User {
        try await repository.fetchUserInfo()
    }
}
