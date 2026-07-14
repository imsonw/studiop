import Foundation

struct ListCartUseCase {
    let repository: StoreRepository

    init(repository: StoreRepository) {
        self.repository = repository
    }

    func callAsFunction() async throws -> [CartItem] {
        try await repository.listCart()
    }
}
