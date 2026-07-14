import Foundation

struct FetchOrderDetailUseCase {
    let repository: OrderRepository

    init(repository: OrderRepository) {
        self.repository = repository
    }

    func callAsFunction(id: String) async throws -> Order {
        try await repository.fetchOrderDetail(id: id)
    }
}
