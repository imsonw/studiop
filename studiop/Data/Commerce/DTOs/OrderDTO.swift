import Foundation

/// Order shape returned by `/stores/checkout/process` and `/stores/checkout/success` — the order
/// created at the end of checkout. See `ProductCategoryDTO`'s note on unconfirmed field names.
struct OrderDTO: Decodable {
    struct LineItemDTO: Decodable {
        let productId: String
        let productName: String?
        let productImage: String?
        let quantity: Int
        let unitPrice: Decimal?

        enum CodingKeys: String, CodingKey {
            case productId = "product_id"
            case productName = "product_name"
            case productImage = "product_image"
            case quantity
            case unitPrice = "unit_price"
        }
    }

    let idEncode: String
    let code: String?
    let status: String?
    let createdAt: String?
    let items: [LineItemDTO]?
    let subtotal: Decimal?
    let shippingFee: Decimal?
    let discount: Decimal?
    let total: Decimal?
    let addressId: String?
    let paymentMethod: String?

    enum CodingKeys: String, CodingKey {
        case idEncode = "id_encode"
        case code
        case status
        case createdAt = "created_at"
        case items
        case subtotal
        case shippingFee = "shipping_fee"
        case discount
        case total
        case addressId = "address_id"
        case paymentMethod = "payment_method"
    }

    func toDomain() -> Order {
        Order(
            id: idEncode,
            code: code ?? "",
            status: status ?? "",
            createdAt: createdAt.flatMap(Self.dateFormatter.date) ?? .distantPast,
            items: (items ?? []).map {
                Order.LineItem(
                    productId: $0.productId,
                    productName: $0.productName ?? "",
                    productImageURL: $0.productImage,
                    quantity: $0.quantity,
                    unitPrice: $0.unitPrice ?? 0
                )
            },
            subtotal: subtotal ?? 0,
            shippingFee: shippingFee ?? 0,
            discount: discount ?? 0,
            total: total ?? 0,
            addressId: addressId,
            paymentMethod: paymentMethod
        )
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()
}
