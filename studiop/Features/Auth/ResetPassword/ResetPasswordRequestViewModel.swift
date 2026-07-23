import Foundation

@MainActor
@Observable
final class ResetPasswordRequestViewModel {
    var email = ValidatedField<String>(value: "")
    var errorMessage: String?
    var successMessage: String?
    var isLoading: Bool = false

    private let resetPasswordUseCase: ResetPasswordUseCase

    init(resetPasswordUseCase: ResetPasswordUseCase) {
        self.resetPasswordUseCase = resetPasswordUseCase
    }

    func requestReset() async {
        email.error = AuthFieldValidator.validateEmail(email.value)?.localizedMessage
        guard email.error == nil else { return }

        isLoading = true
        errorMessage = nil
        successMessage = nil

        do {
            try await resetPasswordUseCase(email: email.value)
            successMessage = "Check your email for a password reset code."
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
