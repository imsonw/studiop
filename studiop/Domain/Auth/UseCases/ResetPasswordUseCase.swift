import Foundation

struct ResetPasswordUseCase {
    let repository: AuthRepository

    init(repository: AuthRepository) {
        self.repository = repository
    }

    func callAsFunction(email: String) async throws {
        try await repository.resetPassword(email: email)
    }
}
