import Foundation

struct FetchAppSlidesUseCase {
    let repository: StaticContentRepository

    func callAsFunction() async throws -> [StaticContentSlide] {
        try await repository.fetchAppSlides()
    }
}
