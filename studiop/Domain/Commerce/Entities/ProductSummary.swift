import Foundation

/// Lighter list-item shape for `/stores/product/popular`, `/stores/product/best-selling`,
/// `/stores/product/list`, and `/related`.
struct ProductSummary: Equatable, Identifiable, Sendable {
    let id: String
    let name: String
    let imageURL: String?
    let price: Decimal
    let compareAtPrice: Decimal?
    let rating: Double
    let ratingCount: Int
    let brandName: String?

    init(
        id: String,
        name: String,
        imageURL: String? = nil,
        price: Decimal,
        compareAtPrice: Decimal? = nil,
        rating: Double = 0,
        ratingCount: Int = 0,
        brandName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.price = price
        self.compareAtPrice = compareAtPrice
        self.rating = rating
        self.ratingCount = ratingCount
        self.brandName = brandName
    }
}
