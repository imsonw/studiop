import Foundation

@MainActor
@Observable
final class RegisterViewModel {
    var name = ValidatedField<String>(value: "")
    var firstName = ValidatedField<String>(value: "")
    var email = ValidatedField<String>(value: "")
    var password = ValidatedField<String>(value: "")
    var passwordConfirmation = ValidatedField<String>(value: "")
    var agreeToTerms = ValidatedField<Bool>(value: false)
    var errorMessage: String?
    var successMessage: String?
    var isLoading: Bool = false

    private let registerUseCase: RegisterUseCase

    init(registerUseCase: RegisterUseCase) {
        self.registerUseCase = registerUseCase
    }

    func register() async {
        name.error = AuthFieldValidator.validateName(name.value)?.localizedMessage
        firstName.error = AuthFieldValidator.validateName(firstName.value)?.localizedMessage
        email.error = AuthFieldValidator.validateEmail(email.value)?.localizedMessage
        password.error = AuthFieldValidator.validatePassword(password.value)?.localizedMessage
        passwordConfirmation.error = AuthFieldValidator
            .validatePasswordConfirmation(passwordConfirmation.value, matches: password.value)?
            .localizedMessage
        agreeToTerms.error = AuthFieldValidator.validateTermsAccepted(agreeToTerms.value)?.localizedMessage

        guard name.error == nil, firstName.error == nil, email.error == nil, password.error == nil,
              passwordConfirmation.error == nil, agreeToTerms.error == nil else {
            return
        }

        isLoading = true
        errorMessage = nil
        successMessage = nil

        do {
            successMessage = try await registerUseCase(
                name: name.value,
                firstName: firstName.value,
                email: email.value,
                password: password.value,
                passwordConfirmation: passwordConfirmation.value,
                agreeToTerms: agreeToTerms.value
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
