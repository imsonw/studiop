import Foundation

/// A cart line item — `/stores/cart/*`. See `ProductCategoryDTO`'s note on unconfirmed field
/// names.
struct CartItemDTO: Decodable {
    let productId: String
    let quantity: Int
    let priceType: String
    let productName: String?
    let productImage: String?
    let unitPrice: Decimal?

    enum CodingKeys: String, CodingKey {
        case productId = "product_id"
        case quantity
        case priceType = "price_type"
        case productName = "product_name"
        case productImage = "product_image"
        case unitPrice = "unit_price"
    }

    func toDomain() -> CartItem {
        CartItem(
            productId: productId,
            quantity: quantity,
            priceType: priceType,
            productName: productName ?? "",
            productImageURL: productImage,
            unitPrice: unitPrice ?? 0
        )
    }
}
