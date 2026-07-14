import Foundation

/// See docs/api-reference.md -> `ReviewRepository`.
protocol ReviewRepository: Sendable {
    /// `status`: `not_reviewed` / `reviewed`.
    func fetchReviewList(status: String?, page: Int?) async throws -> [Review]
    func fetchProductReviews(productId: String, filter: String?, page: Int?) async throws -> [Review]
    func fetchReviewWriteForm(idEncode: String) async throws -> Review
    func submitReview(_ review: Review) async throws -> Review
    func fetchStoreReviewStats(studioIdEncode: String) async throws -> ReviewStoreStats
    func fetchStoreReviews(studioIdEncode: String, filter: String?, page: Int?) async throws -> [Review]
    /// Returns id-encode to reviewed-status.
    func bulkCheckReviewStatus(idEncodes: [String]) async throws -> [String: Bool]
}
