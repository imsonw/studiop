import Foundation

struct LoginUseCase {
    let repository: AuthRepository

    init(repository: AuthRepository) {
        self.repository = repository
    }

    func callAsFunction(email: String, password: String) async throws -> AuthSession {
        try await repository.login(email: email, password: password)
    }
}
