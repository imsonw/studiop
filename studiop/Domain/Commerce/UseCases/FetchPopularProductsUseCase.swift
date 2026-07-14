import Foundation

struct FetchPopularProductsUseCase {
    let repository: StoreRepository

    init(repository: StoreRepository) {
        self.repository = repository
    }

    func callAsFunction(
        limit: Int? = nil,
        query: String? = nil,
        category: String? = nil,
        priceMin: Decimal? = nil,
        priceMax: Decimal? = nil
    ) async throws -> [ProductSummary] {
        try await repository.fetchPopularProducts(
            limit: limit,
            query: query,
            category: category,
            priceMin: priceMin,
            priceMax: priceMax
        )
    }
}
