import Foundation

/// A line item in the shopping cart — `/stores/cart/*`.
struct CartItem: Equatable, Identifiable, Sendable {
    let productId: String
    let quantity: Int
    let priceType: String
    let productName: String
    let productImageURL: String?
    let unitPrice: Decimal

    var id: String { productId }
    var totalPrice: Decimal { unitPrice * Decimal(quantity) }

    init(
        productId: String,
        quantity: Int,
        priceType: String,
        productName: String = "",
        productImageURL: String? = nil,
        unitPrice: Decimal = 0
    ) {
        self.productId = productId
        self.quantity = quantity
        self.priceType = priceType
        self.productName = productName
        self.productImageURL = productImageURL
        self.unitPrice = unitPrice
    }
}
