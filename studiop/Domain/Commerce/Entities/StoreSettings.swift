import Foundation

/// Store/homepage configuration shape shared by `/stores/detail`, `/stores/settings/filters`,
/// `/stores/settings/homepage`, and `/stores/studio/homepage-zones` — each endpoint populates a
/// different subset of these fields.
struct StoreSettings: Equatable, Sendable {
    struct PriceRange: Equatable, Sendable {
        let minPrice: Decimal
        let maxPrice: Decimal

        init(minPrice: Decimal, maxPrice: Decimal) {
            self.minPrice = minPrice
            self.maxPrice = maxPrice
        }
    }

    /// A homepage/store-front section (e.g. "Popular", "New arrivals") and its products.
    struct Zone: Equatable, Identifiable, Sendable {
        let id: String
        let title: String
        let type: String
        let products: [ProductSummary]

        init(id: String, title: String, type: String, products: [ProductSummary] = []) {
            self.id = id
            self.title = title
            self.type = type
            self.products = products
        }
    }

    // Populated by `/stores/detail`.
    let storeId: String?
    let storeName: String?
    let storeDescription: String?
    let logoURL: String?
    let bannerURL: String?
    let rating: Double?

    // Populated by `/stores/settings/filters`.
    let priceRange: PriceRange?
    let categories: [ProductCategory]
    let brands: [Brand]
    let sortOptions: [String]

    // Populated by `/stores/settings/homepage` and `/stores/studio/homepage-zones`.
    let zones: [Zone]

    init(
        storeId: String? = nil,
        storeName: String? = nil,
        storeDescription: String? = nil,
        logoURL: String? = nil,
        bannerURL: String? = nil,
        rating: Double? = nil,
        priceRange: PriceRange? = nil,
        categories: [ProductCategory] = [],
        brands: [Brand] = [],
        sortOptions: [String] = [],
        zones: [Zone] = []
    ) {
        self.storeId = storeId
        self.storeName = storeName
        self.storeDescription = storeDescription
        self.logoURL = logoURL
        self.bannerURL = bannerURL
        self.rating = rating
        self.priceRange = priceRange
        self.categories = categories
        self.brands = brands
        self.sortOptions = sortOptions
        self.zones = zones
    }
}
