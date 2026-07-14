import Foundation

struct FetchCheckoutSuccessUseCase {
    let repository: StoreRepository

    init(repository: StoreRepository) {
        self.repository = repository
    }

    func callAsFunction(id: String) async throws -> Order {
        try await repository.fetchCheckoutSuccess(id: id)
    }
}
