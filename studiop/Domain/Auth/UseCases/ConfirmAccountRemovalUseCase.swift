import Foundation

struct ConfirmAccountRemovalUseCase {
    let repository: UserRepository

    init(repository: UserRepository) {
        self.repository = repository
    }

    func callAsFunction(email: String, code: String) async throws {
        try await repository.confirmAccountRemoval(email: email, code: code)
    }
}
