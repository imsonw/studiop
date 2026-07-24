import Dependencies
import Foundation

private struct UnimplementedStoreRepository: StoreRepository {
    private struct Unimplemented: Error {}

    func fetchStoreFilterSettings(storeId: String) async throws -> StoreSettings { throw Unimplemented() }
    func fetchStoreDetail(id: String) async throws -> StoreSettings { throw Unimplemented() }
    func fetchCategories(id: String) async throws -> [ProductCategory] { throw Unimplemented() }
    func fetchHomepageSettings() async throws -> StoreSettings { throw Unimplemented() }
    func fetchHomepageZones(storeId: String) async throws -> StoreSettings { throw Unimplemented() }

    func fetchPopularProducts(
        limit: Int?, query: String?, category: String?, priceMin: Decimal?, priceMax: Decimal?
    ) async throws -> [ProductSummary] { throw Unimplemented() }

    func fetchBestSellingProducts(
        limit: Int?, query: String?, category: String?, priceMin: Decimal?, priceMax: Decimal?
    ) async throws -> [ProductSummary] { throw Unimplemented() }

    func fetchProductList(
        page: Int?, limit: Int?, query: String?, id: String?, category: String?, priceMin: Decimal?,
        priceMax: Decimal?, minRating: Double?, sort: String?, randomSeed: String?, isMall: Bool?,
        brandId: String?
    ) async throws -> [ProductSummary] { throw Unimplemented() }

    func fetchProductDetail(idEncode: String) async throws -> Product { throw Unimplemented() }
    func fetchRelatedProducts(idEncode: String, limit: Int?, page: Int?) async throws -> [ProductSummary] {
        throw Unimplemented()
    }

    func buyNow(productId: String, quantity: Int, priceType: String) async throws -> CheckoutSession {
        throw Unimplemented()
    }

    func addToCart(productId: String, quantity: Int, priceType: String) async throws -> CartItem {
        throw Unimplemented()
    }
    func listCart() async throws -> [CartItem] { throw Unimplemented() }
    func countCart() async throws -> Int { throw Unimplemented() }
    func updateCart(productId: String, quantity: Int) async throws -> CartItem { throw Unimplemented() }
    func removeFromCart(productId: String) async throws { throw Unimplemented() }
    func clearCart() async throws { throw Unimplemented() }

    func updateCheckoutAddress(id: String, addressId: String) async throws -> CheckoutSession {
        throw Unimplemented()
    }
    func processCheckout(id: String, paymentMethod: String) async throws -> Order { throw Unimplemented() }
    func createCheckout(itemIds: [String]) async throws -> CheckoutSession { throw Unimplemented() }
    func getCheckout(id: String, priceType: String) async throws -> CheckoutSession { throw Unimplemented() }
    func fetchCheckoutSuccess(id: String) async throws -> Order { throw Unimplemented() }
    func fetchBrandList() async throws -> [Brand] { throw Unimplemented() }
}

/// Deterministic canned data for Previews — never touches the real network. Also doubles as a
/// lightweight in-memory cart so preview interactions (add/update/remove) behave sensibly.
private final class PreviewStoreRepository: StoreRepository, @unchecked Sendable {
    private let lock = NSLock()
    private var cart: [CartItem] = [
        CartItem(productId: "p1", quantity: 2, priceType: "retail", productName: "Preview Product", unitPrice: 19.99),
    ]

    static let cannedProducts: [ProductSummary] = [
        ProductSummary(id: "p1", name: "Preview Product", price: 19.99, rating: 4.5, ratingCount: 12),
        ProductSummary(id: "p2", name: "Another Product", price: 9.99, rating: 4.0, ratingCount: 3),
    ]

    func fetchStoreFilterSettings(storeId: String) async throws -> StoreSettings {
        StoreSettings(categories: [ProductCategory(id: "c1", name: "Preview Category")])
    }
    func fetchStoreDetail(id: String) async throws -> StoreSettings {
        StoreSettings(storeId: id, storeName: "Preview Store")
    }
    func fetchCategories(id: String) async throws -> [ProductCategory] {
        [ProductCategory(id: "c1", name: "Preview Category")]
    }
    func fetchHomepageSettings() async throws -> StoreSettings {
        StoreSettings(zones: [StoreSettings.Zone(id: "z1", title: "Popular", type: "popular", products: Self.cannedProducts)])
    }
    func fetchHomepageZones(storeId: String) async throws -> StoreSettings {
        try await fetchHomepageSettings()
    }

    func fetchPopularProducts(
        limit: Int?, query: String?, category: String?, priceMin: Decimal?, priceMax: Decimal?
    ) async throws -> [ProductSummary] { Self.cannedProducts }

    func fetchBestSellingProducts(
        limit: Int?, query: String?, category: String?, priceMin: Decimal?, priceMax: Decimal?
    ) async throws -> [ProductSummary] { Self.cannedProducts }

    func fetchProductList(
        page: Int?, limit: Int?, query: String?, id: String?, category: String?, priceMin: Decimal?,
        priceMax: Decimal?, minRating: Double?, sort: String?, randomSeed: String?, isMall: Bool?,
        brandId: String?
    ) async throws -> [ProductSummary] { Self.cannedProducts }

    func fetchProductDetail(idEncode: String) async throws -> Product {
        Product(
            id: idEncode,
            name: "Preview Product",
            images: [],
            description: "A preview product for SwiftUI previews.",
            priceTiers: [Product.PriceTier(priceType: "retail", price: 19.99)],
            rating: 4.5,
            ratingCount: 12
        )
    }
    func fetchRelatedProducts(idEncode: String, limit: Int?, page: Int?) async throws -> [ProductSummary] {
        Self.cannedProducts
    }

    func buyNow(productId: String, quantity: Int, priceType: String) async throws -> CheckoutSession {
        CheckoutSession(id: "checkout-1", total: 19.99)
    }

    func addToCart(productId: String, quantity: Int, priceType: String) async throws -> CartItem {
        let item = CartItem(productId: productId, quantity: quantity, priceType: priceType, unitPrice: 9.99)
        lock.lock(); cart.append(item); lock.unlock()
        return item
    }
    func listCart() async throws -> [CartItem] {
        lock.lock(); defer { lock.unlock() }
        return cart
    }
    func countCart() async throws -> Int {
        lock.lock(); defer { lock.unlock() }
        return cart.count
    }
    func updateCart(productId: String, quantity: Int) async throws -> CartItem {
        lock.lock(); defer { lock.unlock() }
        if let index = cart.firstIndex(where: { $0.productId == productId }) {
            let updated = CartItem(
                productId: productId, quantity: quantity, priceType: cart[index].priceType,
                productName: cart[index].productName, productImageURL: cart[index].productImageURL,
                unitPrice: cart[index].unitPrice
            )
            cart[index] = updated
            return updated
        }
        return CartItem(productId: productId, quantity: quantity, priceType: "retail")
    }
    func removeFromCart(productId: String) async throws {
        lock.lock(); cart.removeAll { $0.productId == productId }; lock.unlock()
    }
    func clearCart() async throws {
        lock.lock(); cart.removeAll(); lock.unlock()
    }

    func updateCheckoutAddress(id: String, addressId: String) async throws -> CheckoutSession {
        CheckoutSession(id: id, addressId: addressId)
    }
    func processCheckout(id: String, paymentMethod: String) async throws -> Order {
        Order(id: "order-1", code: "ORD-1", status: "processing", paymentMethod: paymentMethod)
    }
    func createCheckout(itemIds: [String]) async throws -> CheckoutSession {
        CheckoutSession(id: "checkout-1", total: 19.99)
    }
    func getCheckout(id: String, priceType: String) async throws -> CheckoutSession {
        CheckoutSession(id: id, total: 19.99)
    }
    func fetchCheckoutSuccess(id: String) async throws -> Order {
        Order(id: id, code: "ORD-1", status: "completed")
    }
    func fetchBrandList() async throws -> [Brand] {
        [Brand(id: "b1", name: "Preview Brand")]
    }
}

private enum StoreRepositoryKey: DependencyKey {
    static var liveValue: StoreRepository {
        @Dependency(\.networkClient) var networkClient
        return StoreRepositoryImpl(networkClient: networkClient)
    }

    static let testValue: StoreRepository = UnimplementedStoreRepository()
    static let previewValue: StoreRepository = PreviewStoreRepository()
}

extension DependencyValues {
    var storeRepository: StoreRepository {
        get { self[StoreRepositoryKey.self] }
        set { self[StoreRepositoryKey.self] = newValue }
    }
}
