import Foundation

/// `GET /stores/product/{idEncode}` — full product detail. See `ProductCategoryDTO`'s note on
/// unconfirmed field names.
struct ProductDTO: Decodable {
    struct PriceTierDTO: Decodable {
        let priceType: String
        let price: Decimal
        let compareAtPrice: Decimal?
        let minimumQuantity: Int?

        enum CodingKeys: String, CodingKey {
            case priceType = "price_type"
            case price
            case compareAtPrice = "compare_at_price"
            case minimumQuantity = "minimum_quantity"
        }
    }

    let idEncode: String
    let name: String
    let images: [String]?
    let description: String?
    let priceTiers: [PriceTierDTO]?
    let rating: Double?
    let ratingCount: Int?
    let categoryId: String?
    let categoryName: String?
    let brandId: String?
    let brandName: String?
    let stock: Int?
    let isMall: Bool?

    enum CodingKeys: String, CodingKey {
        case idEncode = "id_encode"
        case name
        case images
        case description
        case priceTiers = "price_tiers"
        case rating
        case ratingCount = "rating_count"
        case categoryId = "category_id"
        case categoryName = "category_name"
        case brandId = "brand_id"
        case brandName = "brand_name"
        case stock
        case isMall = "is_mall"
    }

    func toDomain() -> Product {
        Product(
            id: idEncode,
            name: name,
            images: images ?? [],
            description: description ?? "",
            priceTiers: (priceTiers ?? []).map {
                Product.PriceTier(
                    priceType: $0.priceType,
                    price: $0.price,
                    compareAtPrice: $0.compareAtPrice,
                    minimumQuantity: $0.minimumQuantity
                )
            },
            rating: rating ?? 0,
            ratingCount: ratingCount ?? 0,
            categoryId: categoryId,
            categoryName: categoryName,
            brandId: brandId,
            brandName: brandName,
            stock: stock,
            isMall: isMall ?? false
        )
    }
}
