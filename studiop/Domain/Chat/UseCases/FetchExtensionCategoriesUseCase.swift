import Foundation

struct FetchExtensionCategoriesUseCase {
    let repository: StaticContentRepository

    func callAsFunction() async throws -> [ExtensionCategory] {
        try await repository.fetchExtensionCategories()
    }
}
