import Foundation

struct RegisterUseCase {
    let repository: AuthRepository

    init(repository: AuthRepository) {
        self.repository = repository
    }

    func callAsFunction(
        name: String,
        firstName: String,
        email: String,
        password: String,
        passwordConfirmation: String,
        agreeToTerms: Bool
    ) async throws -> String {
        if let error = AuthFieldValidator.validateName(name) { throw error }
        if let error = AuthFieldValidator.validateName(firstName) { throw error }
        if let error = AuthFieldValidator.validateEmail(email) { throw error }
        if let error = AuthFieldValidator.validatePassword(password) { throw error }
        if let error = AuthFieldValidator.validatePasswordConfirmation(passwordConfirmation, matches: password) {
            throw error
        }
        if let error = AuthFieldValidator.validateTermsAccepted(agreeToTerms) { throw error }
        return try await repository.register(
            name: name,
            firstName: firstName,
            email: email,
            password: password,
            passwordConfirmation: passwordConfirmation,
            agreeToTerms: agreeToTerms
        )
    }
}
