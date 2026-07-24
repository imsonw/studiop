import Foundation

@MainActor
@Observable
final class CheckoutViewModel {
    private(set) var session: CheckoutSession
    var selectedAddress: Address?
    /// Only `bank_transfer` is documented (docs/api-reference.md's default for
    /// `/stores/checkout/process`) — no other payment_method values are confirmed, so this isn't
    /// offered as a picker with invented options. Real Mollie/WebView payment is Sprint 8's F-024.
    let paymentMethod = "bank_transfer"
    var isProcessing = false
    var errorMessage: String?
    private(set) var completedOrder: Order?

    private let updateCheckoutAddressUseCase: UpdateCheckoutAddressUseCase
    private let processCheckoutUseCase: ProcessCheckoutUseCase
    private let fetchCheckoutSuccessUseCase: FetchCheckoutSuccessUseCase

    init(
        session: CheckoutSession,
        updateCheckoutAddressUseCase: UpdateCheckoutAddressUseCase,
        processCheckoutUseCase: ProcessCheckoutUseCase,
        fetchCheckoutSuccessUseCase: FetchCheckoutSuccessUseCase
    ) {
        self.session = session
        self.updateCheckoutAddressUseCase = updateCheckoutAddressUseCase
        self.processCheckoutUseCase = processCheckoutUseCase
        self.fetchCheckoutSuccessUseCase = fetchCheckoutSuccessUseCase
    }

    func selectAddress(_ address: Address) async {
        selectedAddress = address
        guard let addressId = address.id else { return }
        errorMessage = nil
        do {
            session = try await updateCheckoutAddressUseCase(id: session.id, addressId: String(addressId))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func placeOrder() async {
        guard selectedAddress != nil else {
            errorMessage = "Please select a delivery address."
            return
        }
        isProcessing = true
        errorMessage = nil
        do {
            let order = try await processCheckoutUseCase(id: session.id, paymentMethod: paymentMethod)
            completedOrder = try await fetchCheckoutSuccessUseCase(id: order.id)
        } catch {
            errorMessage = error.localizedDescription
        }
        isProcessing = false
    }
}
