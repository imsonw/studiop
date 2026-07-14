import Foundation
import Testing
@testable import studiop

private final class FakeStaticContentRepository: StaticContentRepository {
    var slidesResult: Result<[StaticContentSlide], Error> = .success([])
    var statisticResult: Result<[AppStatistic], Error> = .success([])
    var reviewsResult: Result<[AppReview], Error> = .success([])
    var categoriesResult: Result<[ExtensionCategory], Error> = .success([])
    var genericSlidesResult: Result<[StaticContentSlide], Error> = .success([])

    private(set) var lastGenericSlidesPath: String?

    func fetchAppSlides() async throws -> [StaticContentSlide] {
        try slidesResult.get()
    }

    func fetchAppStatistic() async throws -> [AppStatistic] {
        try statisticResult.get()
    }

    func fetchAppReviews() async throws -> [AppReview] {
        try reviewsResult.get()
    }

    func fetchExtensionCategories() async throws -> [ExtensionCategory] {
        try categoriesResult.get()
    }

    func fetchSlides(path: String) async throws -> [StaticContentSlide] {
        lastGenericSlidesPath = path
        return try genericSlidesResult.get()
    }
}

private enum TestError: Error, Equatable { case boom }

struct StaticContentUseCaseTests {
    @Test func fetchAppSlidesForwardsResult() async throws {
        let fake = FakeStaticContentRepository()
        let expected = [StaticContentSlide(id: "1", imageURL: "https://x/1.png", title: "Slide", linkURL: nil)]
        fake.slidesResult = .success(expected)
        let useCase = FetchAppSlidesUseCase(repository: fake)

        let result = try await useCase()

        #expect(result == expected)
    }

    @Test func fetchAppSlidesPropagatesError() async throws {
        let fake = FakeStaticContentRepository()
        fake.slidesResult = .failure(TestError.boom)
        let useCase = FetchAppSlidesUseCase(repository: fake)

        do {
            _ = try await useCase()
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error as? TestError == .boom)
        }
    }

    @Test func fetchAppStatisticForwardsResult() async throws {
        let fake = FakeStaticContentRepository()
        let expected = [AppStatistic(id: "1", label: "Users", value: "10k")]
        fake.statisticResult = .success(expected)
        let useCase = FetchAppStatisticUseCase(repository: fake)

        let result = try await useCase()

        #expect(result == expected)
    }

    @Test func fetchAppReviewsForwardsResult() async throws {
        let fake = FakeStaticContentRepository()
        let expected = [AppReview(id: "1", authorName: "Jane", avatarURL: nil, rating: 4.5, comment: "Great")]
        fake.reviewsResult = .success(expected)
        let useCase = FetchAppReviewsUseCase(repository: fake)

        let result = try await useCase()

        #expect(result == expected)
    }

    @Test func fetchExtensionCategoriesForwardsResult() async throws {
        let fake = FakeStaticContentRepository()
        let expected = [ExtensionCategory(id: "1", name: "Beauty", iconURL: nil)]
        fake.categoriesResult = .success(expected)
        let useCase = FetchExtensionCategoriesUseCase(repository: fake)

        let result = try await useCase()

        #expect(result == expected)
    }

    @Test func fetchGenericSlidesForwardsPathAndResult() async throws {
        let fake = FakeStaticContentRepository()
        let expected = [StaticContentSlide(id: "2", imageURL: "https://x/2.png", title: nil, linkURL: nil)]
        fake.genericSlidesResult = .success(expected)
        let useCase = FetchGenericSlidesUseCase(repository: fake)

        let result = try await useCase(path: "/custom/slides")

        #expect(result == expected)
        #expect(fake.lastGenericSlidesPath == "/custom/slides")
    }
}
