import Foundation

struct FetchCategoriesUseCase {
    let repository: StoreRepository

    init(repository: StoreRepository) {
        self.repository = repository
    }

    func callAsFunction(id: String) async throws -> [ProductCategory] {
        try await repository.fetchCategories(id: id)
    }
}
