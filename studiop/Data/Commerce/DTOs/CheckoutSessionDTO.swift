import Foundation

/// A checkout-in-progress — `/stores/checkout/create`, `/stores/checkout/get`,
/// `/stores/checkout/update-address`. See `ProductCategoryDTO`'s note on unconfirmed field names.
struct CheckoutSessionDTO: Decodable {
    struct LineItemDTO: Decodable {
        let productId: String
        let productName: String?
        let quantity: Int
        let priceType: String
        let unitPrice: Decimal?

        enum CodingKeys: String, CodingKey {
            case productId = "product_id"
            case productName = "product_name"
            case quantity
            case priceType = "price_type"
            case unitPrice = "unit_price"
        }
    }

    let idEncode: String
    let items: [LineItemDTO]?
    let subtotal: Decimal?
    let shippingFee: Decimal?
    let discount: Decimal?
    let total: Decimal?
    let addressId: String?
    let paymentMethod: String?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case idEncode = "id_encode"
        case items
        case subtotal
        case shippingFee = "shipping_fee"
        case discount
        case total
        case addressId = "address_id"
        case paymentMethod = "payment_method"
        case status
    }

    func toDomain() -> CheckoutSession {
        CheckoutSession(
            id: idEncode,
            items: (items ?? []).map {
                CheckoutSession.LineItem(
                    productId: $0.productId,
                    productName: $0.productName ?? "",
                    quantity: $0.quantity,
                    priceType: $0.priceType,
                    unitPrice: $0.unitPrice ?? 0
                )
            },
            subtotal: subtotal ?? 0,
            shippingFee: shippingFee ?? 0,
            discount: discount ?? 0,
            total: total ?? 0,
            addressId: addressId,
            paymentMethod: paymentMethod,
            status: status ?? ""
        )
    }
}
