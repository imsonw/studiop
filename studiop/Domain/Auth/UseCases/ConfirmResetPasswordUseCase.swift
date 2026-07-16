import Foundation

struct ConfirmResetPasswordUseCase {
    let repository: AuthRepository

    init(repository: AuthRepository) {
        self.repository = repository
    }

    func callAsFunction(
        email: String,
        resetToken: String,
        newPassword: String,
        newPasswordConfirmation: String
    ) async throws {
        if let error = AuthFieldValidator.validateEmail(email) { throw error }
        if let error = AuthFieldValidator.validatePassword(newPassword) { throw error }
        if let error = AuthFieldValidator.validatePasswordConfirmation(newPasswordConfirmation, matches: newPassword) {
            throw error
        }
        try await repository.confirmResetPassword(
            email: email,
            resetToken: resetToken,
            newPassword: newPassword,
            newPasswordConfirmation: newPasswordConfirmation
        )
    }
}
