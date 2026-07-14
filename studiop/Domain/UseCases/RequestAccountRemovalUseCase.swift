import Foundation

struct RequestAccountRemovalUseCase {
    let repository: UserRepository

    init(repository: UserRepository) {
        self.repository = repository
    }

    func callAsFunction(reason: String) async throws {
        try await repository.requestAccountRemoval(reason: reason)
    }
}
