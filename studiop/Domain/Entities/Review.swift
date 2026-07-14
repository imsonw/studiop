import Foundation

/// A single review (rating, text, media, product/store refs) — `/v1/reviews/*`.
struct Review: Equatable, Identifiable, Sendable {
    let id: String
    let productId: String?
    let storeId: String?
    let rating: Int
    let text: String?
    let mediaURLs: [String]
    let reviewerName: String?
    let createdAt: Date

    init(
        id: String,
        productId: String? = nil,
        storeId: String? = nil,
        rating: Int = 0,
        text: String? = nil,
        mediaURLs: [String] = [],
        reviewerName: String? = nil,
        createdAt: Date = .distantPast
    ) {
        self.id = id
        self.productId = productId
        self.storeId = storeId
        self.rating = rating
        self.text = text
        self.mediaURLs = mediaURLs
        self.reviewerName = reviewerName
        self.createdAt = createdAt
    }
}
