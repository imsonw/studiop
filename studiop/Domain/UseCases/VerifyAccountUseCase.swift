import Foundation

struct VerifyAccountUseCase {
    let repository: AuthRepository

    init(repository: AuthRepository) {
        self.repository = repository
    }

    func callAsFunction(email: String, code: String) async throws {
        try await repository.verifyAccount(email: email, code: code)
    }
}
