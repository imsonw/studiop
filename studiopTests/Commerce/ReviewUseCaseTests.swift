import Foundation
import Testing
@testable import studiop

private struct StubError: Error, Equatable {}

final class FakeReviewRepository: ReviewRepository, @unchecked Sendable {
    var reviewsToReturn: [Review] = [Review(id: "rev-1", rating: 5)]
    var reviewToReturn = Review(id: "rev-1", rating: 5)
    var storeStatsToReturn = ReviewStoreStats(storeId: "store-1", averageRating: 4.5, totalReviews: 10)
    var bulkStatusToReturn: [String: Bool] = ["p-1": true]
    var errorToThrow: Error?

    private(set) var lastReviewListArgs: (status: String?, page: Int?)?
    private(set) var lastProductReviewsArgs: (productId: String, filter: String?, page: Int?)?
    private(set) var lastReviewWriteFormIdEncode: String?
    private(set) var lastSubmittedReview: Review?
    private(set) var lastStoreReviewStatsIdEncode: String?
    private(set) var lastStoreReviewsArgs: (studioIdEncode: String, filter: String?, page: Int?)?
    private(set) var lastBulkCheckIdEncodes: [String]?

    func fetchReviewList(status: String?, page: Int?) async throws -> [Review] {
        lastReviewListArgs = (status, page)
        if let errorToThrow { throw errorToThrow }
        return reviewsToReturn
    }

    func fetchProductReviews(productId: String, filter: String?, page: Int?) async throws -> [Review] {
        lastProductReviewsArgs = (productId, filter, page)
        if let errorToThrow { throw errorToThrow }
        return reviewsToReturn
    }

    func fetchReviewWriteForm(idEncode: String) async throws -> Review {
        lastReviewWriteFormIdEncode = idEncode
        if let errorToThrow { throw errorToThrow }
        return reviewToReturn
    }

    func submitReview(_ review: Review) async throws -> Review {
        lastSubmittedReview = review
        if let errorToThrow { throw errorToThrow }
        return reviewToReturn
    }

    func fetchStoreReviewStats(studioIdEncode: String) async throws -> ReviewStoreStats {
        lastStoreReviewStatsIdEncode = studioIdEncode
        if let errorToThrow { throw errorToThrow }
        return storeStatsToReturn
    }

    func fetchStoreReviews(studioIdEncode: String, filter: String?, page: Int?) async throws -> [Review] {
        lastStoreReviewsArgs = (studioIdEncode, filter, page)
        if let errorToThrow { throw errorToThrow }
        return reviewsToReturn
    }

    func bulkCheckReviewStatus(idEncodes: [String]) async throws -> [String: Bool] {
        lastBulkCheckIdEncodes = idEncodes
        if let errorToThrow { throw errorToThrow }
        return bulkStatusToReturn
    }
}

struct ReviewUseCaseTests {
    @Test func fetchReviewListForwardsFilters() async throws {
        let fake = FakeReviewRepository()
        let useCase = FetchReviewListUseCase(repository: fake)

        let result = try await useCase(status: "not_reviewed", page: 1)

        #expect(fake.lastReviewListArgs?.status == "not_reviewed")
        #expect(fake.lastReviewListArgs?.page == 1)
        #expect(result == fake.reviewsToReturn)
    }

    @Test func fetchProductReviewsForwardsArgs() async throws {
        let fake = FakeReviewRepository()
        let useCase = FetchProductReviewsUseCase(repository: fake)

        let result = try await useCase(productId: "p-1", filter: "5star", page: 2)

        #expect(fake.lastProductReviewsArgs?.productId == "p-1")
        #expect(fake.lastProductReviewsArgs?.filter == "5star")
        #expect(result == fake.reviewsToReturn)
    }

    @Test func fetchReviewWriteFormForwardsIdEncode() async throws {
        let fake = FakeReviewRepository()
        let useCase = FetchReviewWriteFormUseCase(repository: fake)

        let result = try await useCase(idEncode: "enc-1")

        #expect(fake.lastReviewWriteFormIdEncode == "enc-1")
        #expect(result == fake.reviewToReturn)
    }

    @Test func submitReviewForwardsReview() async throws {
        let fake = FakeReviewRepository()
        let useCase = SubmitReviewUseCase(repository: fake)
        let review = Review(id: "draft", productId: "p-1", rating: 4, text: "Great")

        let result = try await useCase(review)

        #expect(fake.lastSubmittedReview == review)
        #expect(result == fake.reviewToReturn)
    }

    @Test func fetchStoreReviewStatsForwardsIdEncode() async throws {
        let fake = FakeReviewRepository()
        let useCase = FetchStoreReviewStatsUseCase(repository: fake)

        let result = try await useCase(studioIdEncode: "studio-1")

        #expect(fake.lastStoreReviewStatsIdEncode == "studio-1")
        #expect(result == fake.storeStatsToReturn)
    }

    @Test func fetchStoreReviewsForwardsArgs() async throws {
        let fake = FakeReviewRepository()
        let useCase = FetchStoreReviewsUseCase(repository: fake)

        let result = try await useCase(studioIdEncode: "studio-1", filter: "recent", page: 3)

        #expect(fake.lastStoreReviewsArgs?.studioIdEncode == "studio-1")
        #expect(fake.lastStoreReviewsArgs?.filter == "recent")
        #expect(result == fake.reviewsToReturn)
    }

    @Test func bulkCheckReviewStatusForwardsIdEncodes() async throws {
        let fake = FakeReviewRepository()
        let useCase = BulkCheckReviewStatusUseCase(repository: fake)

        let result = try await useCase(idEncodes: ["p-1", "p-2"])

        #expect(fake.lastBulkCheckIdEncodes == ["p-1", "p-2"])
        #expect(result == fake.bulkStatusToReturn)
    }

    @Test func submitReviewPropagatesError() async throws {
        let fake = FakeReviewRepository()
        fake.errorToThrow = StubError()
        let useCase = SubmitReviewUseCase(repository: fake)

        await #expect(throws: StubError.self) {
            try await useCase(Review(id: "draft"))
        }
    }
}
