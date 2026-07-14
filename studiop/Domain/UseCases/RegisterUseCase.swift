import Foundation

struct RegisterUseCase {
    let repository: AuthRepository

    init(repository: AuthRepository) {
        self.repository = repository
    }

    func callAsFunction(
        name: String,
        email: String,
        password: String,
        passwordConfirmation: String,
        phone: String? = nil
    ) async throws -> AuthSession {
        try await repository.register(
            name: name,
            email: email,
            password: password,
            passwordConfirmation: passwordConfirmation,
            phone: phone
        )
    }
}
