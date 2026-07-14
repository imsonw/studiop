import Foundation

/// Order summary/detail — `/shop/users/orders*`.
struct Order: Equatable, Identifiable, Sendable {
    struct LineItem: Equatable, Sendable {
        let productId: String
        let productName: String
        let productImageURL: String?
        let quantity: Int
        let unitPrice: Decimal

        init(
            productId: String,
            productName: String = "",
            productImageURL: String? = nil,
            quantity: Int,
            unitPrice: Decimal = 0
        ) {
            self.productId = productId
            self.productName = productName
            self.productImageURL = productImageURL
            self.quantity = quantity
            self.unitPrice = unitPrice
        }
    }

    let id: String
    let code: String
    let status: String
    let createdAt: Date
    let items: [LineItem]
    let subtotal: Decimal
    let shippingFee: Decimal
    let discount: Decimal
    let total: Decimal
    let addressId: String?
    let paymentMethod: String?

    init(
        id: String,
        code: String = "",
        status: String = "",
        createdAt: Date = .distantPast,
        items: [LineItem] = [],
        subtotal: Decimal = 0,
        shippingFee: Decimal = 0,
        discount: Decimal = 0,
        total: Decimal = 0,
        addressId: String? = nil,
        paymentMethod: String? = nil
    ) {
        self.id = id
        self.code = code
        self.status = status
        self.createdAt = createdAt
        self.items = items
        self.subtotal = subtotal
        self.shippingFee = shippingFee
        self.discount = discount
        self.total = total
        self.addressId = addressId
        self.paymentMethod = paymentMethod
    }
}
