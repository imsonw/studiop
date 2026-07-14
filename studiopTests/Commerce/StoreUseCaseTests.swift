import Foundation
import Testing
@testable import studiop

private struct StubError: Error, Equatable {}

final class FakeStoreRepository: StoreRepository, @unchecked Sendable {
    var storeSettingsToReturn = StoreSettings(storeId: "store-1")
    var categoriesToReturn: [ProductCategory] = [ProductCategory(id: "cat-1", name: "Shoes")]
    var productSummariesToReturn: [ProductSummary] = [ProductSummary(id: "p-1", name: "Sneaker", price: 10)]
    var productToReturn = Product(id: "p-1", name: "Sneaker")
    var checkoutSessionToReturn = CheckoutSession(id: "chk-1")
    var cartItemToReturn = CartItem(productId: "p-1", quantity: 1, priceType: "retail")
    var cartItemsToReturn: [CartItem] = [CartItem(productId: "p-1", quantity: 1, priceType: "retail")]
    var cartCountToReturn = 0
    var orderToReturn = Order(id: "order-1")
    var brandsToReturn: [Brand] = [Brand(id: "b-1", name: "Acme")]
    var errorToThrow: Error?

    private(set) var lastStoreFilterSettingsStoreId: String?
    private(set) var lastStoreDetailId: String?
    private(set) var lastCategoriesId: String?
    private(set) var homepageSettingsCallCount = 0
    private(set) var lastHomepageZonesStoreId: String?
    private(set) var lastPopularProductsArgs: (limit: Int?, query: String?, category: String?, priceMin: Decimal?, priceMax: Decimal?)?
    private(set) var lastBestSellingProductsArgs: (limit: Int?, query: String?, category: String?, priceMin: Decimal?, priceMax: Decimal?)?
    private(set) var lastProductListArgs: (
        page: Int?, limit: Int?, query: String?, id: String?, category: String?,
        priceMin: Decimal?, priceMax: Decimal?, minRating: Double?, sort: String?,
        randomSeed: String?, isMall: Bool?, brandId: String?
    )?
    private(set) var lastProductDetailIdEncode: String?
    private(set) var lastRelatedProductsArgs: (idEncode: String, limit: Int?, page: Int?)?
    private(set) var lastBuyNowArgs: (productId: String, quantity: Int, priceType: String)?
    private(set) var lastAddToCartArgs: (productId: String, quantity: Int, priceType: String)?
    private(set) var listCartCallCount = 0
    private(set) var countCartCallCount = 0
    private(set) var lastUpdateCartArgs: (productId: String, quantity: Int)?
    private(set) var lastRemoveFromCartProductId: String?
    private(set) var clearCartCallCount = 0
    private(set) var lastUpdateCheckoutAddressArgs: (id: String, addressId: String)?
    private(set) var lastProcessCheckoutArgs: (id: String, paymentMethod: String)?
    private(set) var lastCreateCheckoutItemIds: [String]?
    private(set) var lastGetCheckoutArgs: (id: String, priceType: String)?
    private(set) var lastCheckoutSuccessId: String?
    private(set) var brandListCallCount = 0

    func fetchStoreFilterSettings(storeId: String) async throws -> StoreSettings {
        lastStoreFilterSettingsStoreId = storeId
        if let errorToThrow { throw errorToThrow }
        return storeSettingsToReturn
    }

    func fetchStoreDetail(id: String) async throws -> StoreSettings {
        lastStoreDetailId = id
        if let errorToThrow { throw errorToThrow }
        return storeSettingsToReturn
    }

    func fetchCategories(id: String) async throws -> [ProductCategory] {
        lastCategoriesId = id
        if let errorToThrow { throw errorToThrow }
        return categoriesToReturn
    }

    func fetchHomepageSettings() async throws -> StoreSettings {
        homepageSettingsCallCount += 1
        if let errorToThrow { throw errorToThrow }
        return storeSettingsToReturn
    }

    func fetchHomepageZones(storeId: String) async throws -> StoreSettings {
        lastHomepageZonesStoreId = storeId
        if let errorToThrow { throw errorToThrow }
        return storeSettingsToReturn
    }

    func fetchPopularProducts(
        limit: Int?, query: String?, category: String?, priceMin: Decimal?, priceMax: Decimal?
    ) async throws -> [ProductSummary] {
        lastPopularProductsArgs = (limit, query, category, priceMin, priceMax)
        if let errorToThrow { throw errorToThrow }
        return productSummariesToReturn
    }

    func fetchBestSellingProducts(
        limit: Int?, query: String?, category: String?, priceMin: Decimal?, priceMax: Decimal?
    ) async throws -> [ProductSummary] {
        lastBestSellingProductsArgs = (limit, query, category, priceMin, priceMax)
        if let errorToThrow { throw errorToThrow }
        return productSummariesToReturn
    }

    func fetchProductList(
        page: Int?, limit: Int?, query: String?, id: String?, category: String?,
        priceMin: Decimal?, priceMax: Decimal?, minRating: Double?, sort: String?,
        randomSeed: String?, isMall: Bool?, brandId: String?
    ) async throws -> [ProductSummary] {
        lastProductListArgs = (page, limit, query, id, category, priceMin, priceMax, minRating, sort, randomSeed, isMall, brandId)
        if let errorToThrow { throw errorToThrow }
        return productSummariesToReturn
    }

    func fetchProductDetail(idEncode: String) async throws -> Product {
        lastProductDetailIdEncode = idEncode
        if let errorToThrow { throw errorToThrow }
        return productToReturn
    }

    func fetchRelatedProducts(idEncode: String, limit: Int?, page: Int?) async throws -> [ProductSummary] {
        lastRelatedProductsArgs = (idEncode, limit, page)
        if let errorToThrow { throw errorToThrow }
        return productSummariesToReturn
    }

    func buyNow(productId: String, quantity: Int, priceType: String) async throws -> CheckoutSession {
        lastBuyNowArgs = (productId, quantity, priceType)
        if let errorToThrow { throw errorToThrow }
        return checkoutSessionToReturn
    }

    func addToCart(productId: String, quantity: Int, priceType: String) async throws -> CartItem {
        lastAddToCartArgs = (productId, quantity, priceType)
        if let errorToThrow { throw errorToThrow }
        return cartItemToReturn
    }

    func listCart() async throws -> [CartItem] {
        listCartCallCount += 1
        if let errorToThrow { throw errorToThrow }
        return cartItemsToReturn
    }

    func countCart() async throws -> Int {
        countCartCallCount += 1
        if let errorToThrow { throw errorToThrow }
        return cartCountToReturn
    }

    func updateCart(productId: String, quantity: Int) async throws -> CartItem {
        lastUpdateCartArgs = (productId, quantity)
        if let errorToThrow { throw errorToThrow }
        return cartItemToReturn
    }

    func removeFromCart(productId: String) async throws {
        lastRemoveFromCartProductId = productId
        if let errorToThrow { throw errorToThrow }
    }

    func clearCart() async throws {
        clearCartCallCount += 1
        if let errorToThrow { throw errorToThrow }
    }

    func updateCheckoutAddress(id: String, addressId: String) async throws -> CheckoutSession {
        lastUpdateCheckoutAddressArgs = (id, addressId)
        if let errorToThrow { throw errorToThrow }
        return checkoutSessionToReturn
    }

    func processCheckout(id: String, paymentMethod: String) async throws -> Order {
        lastProcessCheckoutArgs = (id, paymentMethod)
        if let errorToThrow { throw errorToThrow }
        return orderToReturn
    }

    func createCheckout(itemIds: [String]) async throws -> CheckoutSession {
        lastCreateCheckoutItemIds = itemIds
        if let errorToThrow { throw errorToThrow }
        return checkoutSessionToReturn
    }

    func getCheckout(id: String, priceType: String) async throws -> CheckoutSession {
        lastGetCheckoutArgs = (id, priceType)
        if let errorToThrow { throw errorToThrow }
        return checkoutSessionToReturn
    }

    func fetchCheckoutSuccess(id: String) async throws -> Order {
        lastCheckoutSuccessId = id
        if let errorToThrow { throw errorToThrow }
        return orderToReturn
    }

    func fetchBrandList() async throws -> [Brand] {
        brandListCallCount += 1
        if let errorToThrow { throw errorToThrow }
        return brandsToReturn
    }
}

struct StoreUseCaseTests {
    @Test func fetchStoreFilterSettingsForwardsStoreId() async throws {
        let fake = FakeStoreRepository()
        let useCase = FetchStoreFilterSettingsUseCase(repository: fake)

        let result = try await useCase(storeId: "store-42")

        #expect(fake.lastStoreFilterSettingsStoreId == "store-42")
        #expect(result == fake.storeSettingsToReturn)
    }

    @Test func fetchStoreDetailForwardsId() async throws {
        let fake = FakeStoreRepository()
        let useCase = FetchStoreDetailUseCase(repository: fake)

        let result = try await useCase(id: "store-1")

        #expect(fake.lastStoreDetailId == "store-1")
        #expect(result == fake.storeSettingsToReturn)
    }

    @Test func fetchCategoriesForwardsId() async throws {
        let fake = FakeStoreRepository()
        let useCase = FetchCategoriesUseCase(repository: fake)

        let result = try await useCase(id: "cat-parent")

        #expect(fake.lastCategoriesId == "cat-parent")
        #expect(result == fake.categoriesToReturn)
    }

    @Test func fetchHomepageSettingsReturnsResult() async throws {
        let fake = FakeStoreRepository()
        let useCase = FetchHomepageSettingsUseCase(repository: fake)

        let result = try await useCase()

        #expect(fake.homepageSettingsCallCount == 1)
        #expect(result == fake.storeSettingsToReturn)
    }

    @Test func fetchHomepageZonesForwardsStoreId() async throws {
        let fake = FakeStoreRepository()
        let useCase = FetchHomepageZonesUseCase(repository: fake)

        let result = try await useCase(storeId: "store-1")

        #expect(fake.lastHomepageZonesStoreId == "store-1")
        #expect(result == fake.storeSettingsToReturn)
    }

    @Test func fetchPopularProductsForwardsFilters() async throws {
        let fake = FakeStoreRepository()
        let useCase = FetchPopularProductsUseCase(repository: fake)

        let result = try await useCase(limit: 10, query: "shoe", category: "cat-1", priceMin: 5, priceMax: 50)

        #expect(fake.lastPopularProductsArgs?.limit == 10)
        #expect(fake.lastPopularProductsArgs?.query == "shoe")
        #expect(result == fake.productSummariesToReturn)
    }

    @Test func fetchBestSellingProductsForwardsFilters() async throws {
        let fake = FakeStoreRepository()
        let useCase = FetchBestSellingProductsUseCase(repository: fake)

        let result = try await useCase(limit: 5, query: nil, category: nil, priceMin: nil, priceMax: nil)

        #expect(fake.lastBestSellingProductsArgs?.limit == 5)
        #expect(result == fake.productSummariesToReturn)
    }

    @Test func fetchProductListForwardsAllFilters() async throws {
        let fake = FakeStoreRepository()
        let useCase = FetchProductListUseCase(repository: fake)

        let result = try await useCase(
            page: 2, limit: 20, query: "q", id: "id-1", category: "cat-1",
            priceMin: 1, priceMax: 100, minRating: 4, sort: "price_asc",
            randomSeed: "seed", isMall: true, brandId: "brand-1"
        )

        #expect(fake.lastProductListArgs?.page == 2)
        #expect(fake.lastProductListArgs?.brandId == "brand-1")
        #expect(fake.lastProductListArgs?.isMall == true)
        #expect(result == fake.productSummariesToReturn)
    }

    @Test func fetchProductDetailForwardsIdEncode() async throws {
        let fake = FakeStoreRepository()
        let useCase = FetchProductDetailUseCase(repository: fake)

        let result = try await useCase(idEncode: "abc123")

        #expect(fake.lastProductDetailIdEncode == "abc123")
        #expect(result == fake.productToReturn)
    }

    @Test func fetchRelatedProductsForwardsArgs() async throws {
        let fake = FakeStoreRepository()
        let useCase = FetchRelatedProductsUseCase(repository: fake)

        let result = try await useCase(idEncode: "abc123", limit: 5, page: 1)

        #expect(fake.lastRelatedProductsArgs?.idEncode == "abc123")
        #expect(fake.lastRelatedProductsArgs?.limit == 5)
        #expect(result == fake.productSummariesToReturn)
    }

    @Test func buyNowForwardsArgs() async throws {
        let fake = FakeStoreRepository()
        let useCase = BuyNowUseCase(repository: fake)

        let result = try await useCase(productId: "p-1", quantity: 2, priceType: "retail")

        #expect(fake.lastBuyNowArgs?.productId == "p-1")
        #expect(fake.lastBuyNowArgs?.quantity == 2)
        #expect(result == fake.checkoutSessionToReturn)
    }

    @Test func addToCartForwardsArgs() async throws {
        let fake = FakeStoreRepository()
        let useCase = AddToCartUseCase(repository: fake)

        let result = try await useCase(productId: "p-1", quantity: 3, priceType: "retail")

        #expect(fake.lastAddToCartArgs?.productId == "p-1")
        #expect(fake.lastAddToCartArgs?.quantity == 3)
        #expect(result == fake.cartItemToReturn)
    }

    @Test func listCartReturnsItems() async throws {
        let fake = FakeStoreRepository()
        let useCase = ListCartUseCase(repository: fake)

        let result = try await useCase()

        #expect(fake.listCartCallCount == 1)
        #expect(result == fake.cartItemsToReturn)
    }

    @Test func countCartReturnsCount() async throws {
        let fake = FakeStoreRepository()
        fake.cartCountToReturn = 4
        let useCase = CountCartUseCase(repository: fake)

        let result = try await useCase()

        #expect(fake.countCartCallCount == 1)
        #expect(result == 4)
    }

    @Test func updateCartForwardsArgs() async throws {
        let fake = FakeStoreRepository()
        let useCase = UpdateCartUseCase(repository: fake)

        let result = try await useCase(productId: "p-1", quantity: 9)

        #expect(fake.lastUpdateCartArgs?.productId == "p-1")
        #expect(fake.lastUpdateCartArgs?.quantity == 9)
        #expect(result == fake.cartItemToReturn)
    }

    @Test func removeFromCartForwardsProductId() async throws {
        let fake = FakeStoreRepository()
        let useCase = RemoveFromCartUseCase(repository: fake)

        try await useCase(productId: "p-1")

        #expect(fake.lastRemoveFromCartProductId == "p-1")
    }

    @Test func clearCartInvokesRepository() async throws {
        let fake = FakeStoreRepository()
        let useCase = ClearCartUseCase(repository: fake)

        try await useCase()

        #expect(fake.clearCartCallCount == 1)
    }

    @Test func updateCheckoutAddressForwardsArgs() async throws {
        let fake = FakeStoreRepository()
        let useCase = UpdateCheckoutAddressUseCase(repository: fake)

        let result = try await useCase(id: "chk-1", addressId: "addr-1")

        #expect(fake.lastUpdateCheckoutAddressArgs?.id == "chk-1")
        #expect(fake.lastUpdateCheckoutAddressArgs?.addressId == "addr-1")
        #expect(result == fake.checkoutSessionToReturn)
    }

    @Test func processCheckoutDefaultsToBankTransfer() async throws {
        let fake = FakeStoreRepository()
        let useCase = ProcessCheckoutUseCase(repository: fake)

        let result = try await useCase(id: "chk-1")

        #expect(fake.lastProcessCheckoutArgs?.paymentMethod == "bank_transfer")
        #expect(result == fake.orderToReturn)
    }

    @Test func createCheckoutForwardsItemIds() async throws {
        let fake = FakeStoreRepository()
        let useCase = CreateCheckoutUseCase(repository: fake)

        let result = try await useCase(itemIds: ["p-1", "p-2"])

        #expect(fake.lastCreateCheckoutItemIds == ["p-1", "p-2"])
        #expect(result == fake.checkoutSessionToReturn)
    }

    @Test func getCheckoutForwardsArgs() async throws {
        let fake = FakeStoreRepository()
        let useCase = GetCheckoutUseCase(repository: fake)

        let result = try await useCase(id: "chk-1", priceType: "retail")

        #expect(fake.lastGetCheckoutArgs?.id == "chk-1")
        #expect(fake.lastGetCheckoutArgs?.priceType == "retail")
        #expect(result == fake.checkoutSessionToReturn)
    }

    @Test func fetchCheckoutSuccessForwardsId() async throws {
        let fake = FakeStoreRepository()
        let useCase = FetchCheckoutSuccessUseCase(repository: fake)

        let result = try await useCase(id: "chk-1")

        #expect(fake.lastCheckoutSuccessId == "chk-1")
        #expect(result == fake.orderToReturn)
    }

    @Test func fetchBrandListReturnsBrands() async throws {
        let fake = FakeStoreRepository()
        let useCase = FetchBrandListUseCase(repository: fake)

        let result = try await useCase()

        #expect(fake.brandListCallCount == 1)
        #expect(result == fake.brandsToReturn)
    }

    @Test func fetchProductDetailPropagatesError() async throws {
        let fake = FakeStoreRepository()
        fake.errorToThrow = StubError()
        let useCase = FetchProductDetailUseCase(repository: fake)

        await #expect(throws: StubError.self) {
            try await useCase(idEncode: "abc")
        }
    }
}
