import Foundation

/// Catalog / cart / checkout — see docs/api-reference.md -> `StoreRepository`.
protocol StoreRepository: Sendable {
    func fetchStoreFilterSettings(storeId: String) async throws -> StoreSettings
    func fetchStoreDetail(id: String) async throws -> StoreSettings
    func fetchCategories(id: String) async throws -> [ProductCategory]
    func fetchHomepageSettings() async throws -> StoreSettings
    func fetchHomepageZones(storeId: String) async throws -> StoreSettings

    func fetchPopularProducts(
        limit: Int?,
        query: String?,
        category: String?,
        priceMin: Decimal?,
        priceMax: Decimal?
    ) async throws -> [ProductSummary]

    func fetchBestSellingProducts(
        limit: Int?,
        query: String?,
        category: String?,
        priceMin: Decimal?,
        priceMax: Decimal?
    ) async throws -> [ProductSummary]

    func fetchProductList(
        page: Int?,
        limit: Int?,
        query: String?,
        id: String?,
        category: String?,
        priceMin: Decimal?,
        priceMax: Decimal?,
        minRating: Double?,
        sort: String?,
        randomSeed: String?,
        isMall: Bool?,
        brandId: String?
    ) async throws -> [ProductSummary]

    func fetchProductDetail(idEncode: String) async throws -> Product
    func fetchRelatedProducts(idEncode: String, limit: Int?, page: Int?) async throws -> [ProductSummary]

    func buyNow(productId: String, quantity: Int, priceType: String) async throws -> CheckoutSession

    func addToCart(productId: String, quantity: Int, priceType: String) async throws -> CartItem
    func listCart() async throws -> [CartItem]
    func countCart() async throws -> Int
    func updateCart(productId: String, quantity: Int) async throws -> CartItem
    func removeFromCart(productId: String) async throws
    func clearCart() async throws

    func updateCheckoutAddress(id: String, addressId: String) async throws -> CheckoutSession
    func processCheckout(id: String, paymentMethod: String) async throws -> Order
    func createCheckout(itemIds: [String]) async throws -> CheckoutSession
    func getCheckout(id: String, priceType: String) async throws -> CheckoutSession
    func fetchCheckoutSuccess(id: String) async throws -> Order

    func fetchBrandList() async throws -> [Brand]
}
