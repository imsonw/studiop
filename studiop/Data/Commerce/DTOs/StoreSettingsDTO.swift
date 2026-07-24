import Foundation

/// Shared response shape for `/stores/detail`, `/stores/settings/filters`,
/// `/stores/settings/homepage`, `/stores/studio/homepage-zones` — each endpoint populates a
/// different subset of these fields, matching `StoreSettings`'s own doc comment. See
/// `ProductCategoryDTO`'s note on unconfirmed field names.
struct StoreSettingsDTO: Decodable {
    struct PriceRangeDTO: Decodable {
        let minPrice: Decimal
        let maxPrice: Decimal

        enum CodingKeys: String, CodingKey {
            case minPrice = "min_price"
            case maxPrice = "max_price"
        }
    }

    struct ZoneDTO: Decodable {
        let idEncode: String
        let title: String
        let type: String
        let products: [ProductSummaryDTO]?

        enum CodingKeys: String, CodingKey {
            case idEncode = "id_encode"
            case title
            case type
            case products
        }
    }

    let storeId: String?
    let storeName: String?
    let storeDescription: String?
    let logo: String?
    let banner: String?
    let rating: Double?
    let priceRange: PriceRangeDTO?
    let categories: [ProductCategoryDTO]?
    let brands: [BrandDTO]?
    let sortOptions: [String]?
    let zones: [ZoneDTO]?

    enum CodingKeys: String, CodingKey {
        case storeId = "store_id"
        case storeName = "store_name"
        case storeDescription = "store_description"
        case logo
        case banner
        case rating
        case priceRange = "price_range"
        case categories
        case brands
        case sortOptions = "sort_options"
        case zones
    }

    func toDomain() -> StoreSettings {
        StoreSettings(
            storeId: storeId,
            storeName: storeName,
            storeDescription: storeDescription,
            logoURL: logo,
            bannerURL: banner,
            rating: rating,
            priceRange: priceRange.map { StoreSettings.PriceRange(minPrice: $0.minPrice, maxPrice: $0.maxPrice) },
            categories: (categories ?? []).map { $0.toDomain() },
            brands: (brands ?? []).map { $0.toDomain() },
            sortOptions: sortOptions ?? [],
            zones: (zones ?? []).map { zone in
                StoreSettings.Zone(
                    id: zone.idEncode,
                    title: zone.title,
                    type: zone.type,
                    products: (zone.products ?? []).map { $0.toDomain() }
                )
            }
        )
    }
}
