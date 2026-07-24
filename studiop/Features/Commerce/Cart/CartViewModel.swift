import Foundation

@MainActor
@Observable
final class CartViewModel {
    private(set) var items: [CartItem] = []
    var isLoading = false
    var errorMessage: String?

    var total: Decimal { items.reduce(0) { $0 + $1.totalPrice } }

    private let listCartUseCase: ListCartUseCase
    private let updateCartUseCase: UpdateCartUseCase
    private let removeFromCartUseCase: RemoveFromCartUseCase
    private let clearCartUseCase: ClearCartUseCase
    private let createCheckoutUseCase: CreateCheckoutUseCase

    init(
        listCartUseCase: ListCartUseCase,
        updateCartUseCase: UpdateCartUseCase,
        removeFromCartUseCase: RemoveFromCartUseCase,
        clearCartUseCase: ClearCartUseCase,
        createCheckoutUseCase: CreateCheckoutUseCase
    ) {
        self.listCartUseCase = listCartUseCase
        self.updateCartUseCase = updateCartUseCase
        self.removeFromCartUseCase = removeFromCartUseCase
        self.clearCartUseCase = clearCartUseCase
        self.createCheckoutUseCase = createCheckoutUseCase
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            items = try await listCartUseCase()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func updateQuantity(productId: String, quantity: Int) async {
        guard quantity > 0 else {
            await remove(productId: productId)
            return
        }
        do {
            _ = try await updateCartUseCase(productId: productId, quantity: quantity)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func remove(productId: String) async {
        do {
            try await removeFromCartUseCase(productId: productId)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clear() async {
        do {
            try await clearCartUseCase()
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func checkout() async -> CheckoutSession? {
        do {
            return try await createCheckoutUseCase(itemIds: items.map(\.productId))
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
