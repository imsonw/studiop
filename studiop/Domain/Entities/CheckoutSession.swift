import Foundation

/// A checkout-in-progress — `/stores/checkout/create`, `/stores/checkout/get`,
/// `/stores/checkout/process`.
struct CheckoutSession: Equatable, Identifiable, Sendable {
    struct LineItem: Equatable, Sendable {
        let productId: String
        let productName: String
        let quantity: Int
        let priceType: String
        let unitPrice: Decimal

        init(
            productId: String,
            productName: String = "",
            quantity: Int,
            priceType: String,
            unitPrice: Decimal = 0
        ) {
            self.productId = productId
            self.productName = productName
            self.quantity = quantity
            self.priceType = priceType
            self.unitPrice = unitPrice
        }
    }

    let id: String
    let items: [LineItem]
    let subtotal: Decimal
    let shippingFee: Decimal
    let discount: Decimal
    let total: Decimal
    let addressId: String?
    let paymentMethod: String?
    let status: String

    init(
        id: String,
        items: [LineItem] = [],
        subtotal: Decimal = 0,
        shippingFee: Decimal = 0,
        discount: Decimal = 0,
        total: Decimal = 0,
        addressId: String? = nil,
        paymentMethod: String? = nil,
        status: String = ""
    ) {
        self.id = id
        self.items = items
        self.subtotal = subtotal
        self.shippingFee = shippingFee
        self.discount = discount
        self.total = total
        self.addressId = addressId
        self.paymentMethod = paymentMethod
        self.status = status
    }
}
