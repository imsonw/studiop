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
        try await repository.confirmResetPassword(
            email: email,
            resetToken: resetToken,
            newPassword: newPassword,
            newPasswordConfirmation: newPasswordConfirmation
        )
    }
}
