import Foundation

@MainActor
@Observable
final class ResetPasswordConfirmViewModel {
    var email = ValidatedField<String>(value: "")
    var resetToken: String = ""
    var newPassword = ValidatedField<String>(value: "")
    var newPasswordConfirmation = ValidatedField<String>(value: "")
    var errorMessage: String?
    var successMessage: String?
    var isLoading: Bool = false

    private let confirmResetPasswordUseCase: ConfirmResetPasswordUseCase

    init(confirmResetPasswordUseCase: ConfirmResetPasswordUseCase) {
        self.confirmResetPasswordUseCase = confirmResetPasswordUseCase
    }

    func confirmReset() async {
        email.error = AuthFieldValidator.validateEmail(email.value)?.localizedMessage
        newPassword.error = AuthFieldValidator.validatePassword(newPassword.value)?.localizedMessage
        newPasswordConfirmation.error = AuthFieldValidator
            .validatePasswordConfirmation(newPasswordConfirmation.value, matches: newPassword.value)?
            .localizedMessage

        guard email.error == nil, newPassword.error == nil, newPasswordConfirmation.error == nil else {
            return
        }

        isLoading = true
        errorMessage = nil
        successMessage = nil

        do {
            try await confirmResetPasswordUseCase(
                email: email.value,
                resetToken: resetToken,
                newPassword: newPassword.value,
                newPasswordConfirmation: newPasswordConfirmation.value
            )
            successMessage = "Password reset successful. You can now log in with your new password."
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
