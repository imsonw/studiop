import Foundation

struct LoginUseCase {
    let repository: AuthRepository

    init(repository: AuthRepository) {
        self.repository = repository
    }

    func callAsFunction(email: String, password: String) async throws -> AuthSession {
        if let error = AuthFieldValidator.validateEmail(email) {
            throw error
        }
        return try await repository.login(email: email, password: password)
    }
}
