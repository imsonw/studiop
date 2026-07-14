import Foundation

/// The provider hand-off payload (e.g. Mollie checkout URL, opened in a WebView) —
/// `POST /mobile/payments/create`.
struct PaymentHandoff: Equatable, Sendable {
    let paymentId: String
    let provider: String
    let checkoutURL: String
    let status: String?

    init(paymentId: String, provider: String, checkoutURL: String, status: String? = nil) {
        self.paymentId = paymentId
        self.provider = provider
        self.checkoutURL = checkoutURL
        self.status = status
    }
}
