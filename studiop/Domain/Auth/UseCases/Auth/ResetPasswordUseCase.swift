import Foundation

struct ResetPasswordUseCase {
    let repository: AuthRepository

    init(repository: AuthRepository) {
        self.repository = repository
    }

    func callAsFunction(email: String) async throws {
        if let error = AuthFieldValidator.validateEmail(email) { throw error }
        try await repository.resetPassword(email: email)
    }
}
