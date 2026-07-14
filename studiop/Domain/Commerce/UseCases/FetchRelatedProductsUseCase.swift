import Foundation

struct FetchRelatedProductsUseCase {
    let repository: StoreRepository

    init(repository: StoreRepository) {
        self.repository = repository
    }

    func callAsFunction(idEncode: String, limit: Int? = nil, page: Int? = nil) async throws -> [ProductSummary] {
        try await repository.fetchRelatedProducts(idEncode: idEncode, limit: limit, page: page)
    }
}
