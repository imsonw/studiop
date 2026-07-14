import Foundation

/// A voucher code + its redemption result — `/vouchers/code/redeem`.
struct Voucher: Equatable, Sendable {
    let code: String
    let isValid: Bool
    let discountAmount: Decimal?
    let message: String?
    let orderId: String?

    init(
        code: String,
        isValid: Bool = true,
        discountAmount: Decimal? = nil,
        message: String? = nil,
        orderId: String? = nil
    ) {
        self.code = code
        self.isValid = isValid
        self.discountAmount = discountAmount
        self.message = message
        self.orderId = orderId
    }
}
