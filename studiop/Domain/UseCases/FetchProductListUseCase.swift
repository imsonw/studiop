import Foundation

struct FetchProductListUseCase {
    let repository: StoreRepository

    init(repository: StoreRepository) {
        self.repository = repository
    }

    func callAsFunction(
        page: Int? = nil,
        limit: Int? = nil,
        query: String? = nil,
        id: String? = nil,
        category: String? = nil,
        priceMin: Decimal? = nil,
        priceMax: Decimal? = nil,
        minRating: Double? = nil,
        sort: String? = nil,
        randomSeed: String? = nil,
        isMall: Bool? = nil,
        brandId: String? = nil
    ) async throws -> [ProductSummary] {
        try await repository.fetchProductList(
            page: page,
            limit: limit,
            query: query,
            id: id,
            category: category,
            priceMin: priceMin,
            priceMax: priceMax,
            minRating: minRating,
            sort: sort,
            randomSeed: randomSeed,
            isMall: isMall,
            brandId: brandId
        )
    }
}
