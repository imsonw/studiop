import Foundation

/// Aggregate store rating stats — `GET /v1/reviews/store-stats/{studioIdEncode}`.
struct ReviewStoreStats: Equatable, Sendable {
    let storeId: String
    let averageRating: Double
    let totalReviews: Int
    /// Star rating (1...5) to how many reviews gave that rating.
    let ratingBreakdown: [Int: Int]

    init(
        storeId: String,
        averageRating: Double = 0,
        totalReviews: Int = 0,
        ratingBreakdown: [Int: Int] = [:]
    ) {
        self.storeId = storeId
        self.averageRating = averageRating
        self.totalReviews = totalReviews
        self.ratingBreakdown = ratingBreakdown
    }
}
