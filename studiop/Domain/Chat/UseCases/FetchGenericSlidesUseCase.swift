import Foundation

struct FetchGenericSlidesUseCase {
    let repository: StaticContentRepository

    func callAsFunction(path: String) async throws -> [StaticContentSlide] {
        try await repository.fetchSlides(path: path)
    }
}
