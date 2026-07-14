import Foundation

struct FetchOrderStatusFiltersUseCase {
    let repository: OrderRepository

    init(repository: OrderRepository) {
        self.repository = repository
    }

    func callAsFunction() async throws -> [OrderStatusFilter] {
        try await repository.fetchOrderStatusFilters()
    }
}
