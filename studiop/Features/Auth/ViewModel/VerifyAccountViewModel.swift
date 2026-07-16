import Foundation

@MainActor
@Observable
final class VerifyAccountViewModel {
    var email = ValidatedField<String>(value: "")
    var code: String = ""
    var errorMessage: String?
    var successMessage: String?
    var isLoading: Bool = false

    private let verifyAccountUseCase: VerifyAccountUseCase

    init(verifyAccountUseCase: VerifyAccountUseCase) {
        self.verifyAccountUseCase = verifyAccountUseCase
    }

    func verify() async {
        email.error = AuthFieldValidator.validateEmail(email.value)?.localizedMessage
        guard email.error == nil else { return }

        isLoading = true
        errorMessage = nil
        successMessage = nil

        do {
            try await verifyAccountUseCase(email: email.value, code: code)
            successMessage = "Account verified. You can now log in."
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
