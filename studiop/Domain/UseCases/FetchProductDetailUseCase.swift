import Foundation

struct FetchProductDetailUseCase {
    let repository: StoreRepository

    init(repository: StoreRepository) {
        self.repository = repository
    }

    func callAsFunction(idEncode: String) async throws -> Product {
        try await repository.fetchProductDetail(idEncode: idEncode)
    }
}
