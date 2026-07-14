import Foundation

/// Full product detail — `GET /stores/product/{idEncode}` and list/detail endpoints.
struct Product: Equatable, Identifiable, Sendable {
    /// A single price point for a given `priceType` (e.g. retail vs. wholesale tiers).
    struct PriceTier: Equatable, Sendable {
        let priceType: String
        let price: Decimal
        let compareAtPrice: Decimal?
        let minimumQuantity: Int?

        init(
            priceType: String,
            price: Decimal,
            compareAtPrice: Decimal? = nil,
            minimumQuantity: Int? = nil
        ) {
            self.priceType = priceType
            self.price = price
            self.compareAtPrice = compareAtPrice
            self.minimumQuantity = minimumQuantity
        }
    }

    let id: String
    let name: String
    let images: [String]
    let description: String
    let priceTiers: [PriceTier]
    let rating: Double
    let ratingCount: Int
    let categoryId: String?
    let categoryName: String?
    let brandId: String?
    let brandName: String?
    let stock: Int?
    let isMall: Bool

    init(
        id: String,
        name: String,
        images: [String] = [],
        description: String = "",
        priceTiers: [PriceTier] = [],
        rating: Double = 0,
        ratingCount: Int = 0,
        categoryId: String? = nil,
        categoryName: String? = nil,
        brandId: String? = nil,
        brandName: String? = nil,
        stock: Int? = nil,
        isMall: Bool = false
    ) {
        self.id = id
        self.name = name
        self.images = images
        self.description = description
        self.priceTiers = priceTiers
        self.rating = rating
        self.ratingCount = ratingCount
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.brandId = brandId
        self.brandName = brandName
        self.stock = stock
        self.isMall = isMall
    }
}
