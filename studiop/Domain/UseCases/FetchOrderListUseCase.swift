import Foundation

struct FetchOrderListUseCase {
    let repository: OrderRepository

    init(repository: OrderRepository) {
        self.repository = repository
    }

    func callAsFunction(
        page: Int? = nil,
        status: String? = nil,
        search: String? = nil,
        createFrom: Date? = nil
    ) async throws -> [Order] {
        try await repository.fetchOrders(page: page, status: status, search: search, createFrom: createFrom)
    }
}
