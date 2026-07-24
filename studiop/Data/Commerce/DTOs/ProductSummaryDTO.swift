import Foundation

/// List-item shape for `/stores/product/popular`, `/stores/product/best-selling`,
/// `/stores/product/list`, `/stores/product/{id}/related`. See `ProductCategoryDTO`'s note on
/// unconfirmed field names.
struct ProductSummaryDTO: Decodable {
    let idEncode: String
    let name: String
    let image: String?
    let price: Decimal
    let compareAtPrice: Decimal?
    let rating: Double?
    let ratingCount: Int?
    let brandName: String?

    enum CodingKeys: String, CodingKey {
        case idEncode = "id_encode"
        case name
        case image
        case price
        case compareAtPrice = "compare_at_price"
        case rating
        case ratingCount = "rating_count"
        case brandName = "brand_name"
    }

    func toDomain() -> ProductSummary {
        ProductSummary(
            id: idEncode,
            name: name,
            imageURL: image,
            price: price,
            compareAtPrice: compareAtPrice,
            rating: rating ?? 0,
            ratingCount: ratingCount ?? 0,
            brandName: brandName
        )
    }
}
