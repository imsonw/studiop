import Foundation

@MainActor
@Observable
final class StorefrontViewModel {
    private(set) var categories: [ProductCategory] = []
    private(set) var brands: [Brand] = []
    private(set) var products: [ProductSummary] = []
    var selectedCategoryId: String?
    var isLoading = false
    var errorMessage: String?

    private let fetchCategoriesUseCase: FetchCategoriesUseCase
    private let fetchProductListUseCase: FetchProductListUseCase
    private let fetchBrandListUseCase: FetchBrandListUseCase
    private let imageLoading: ImageLoading

    init(
        fetchCategoriesUseCase: FetchCategoriesUseCase,
        fetchProductListUseCase: FetchProductListUseCase,
        fetchBrandListUseCase: FetchBrandListUseCase,
        imageLoading: ImageLoading
    ) {
        self.fetchCategoriesUseCase = fetchCategoriesUseCase
        self.fetchProductListUseCase = fetchProductListUseCase
        self.fetchBrandListUseCase = fetchBrandListUseCase
        self.imageLoading = imageLoading
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            // Top-level storefront (no specific seller/studio in scope yet -- studio/shop pages
            // are a separate, later feature per docs/features.md) -- passing an empty `id` for
            // the root category tree. UNCONFIRMED against real traffic; flagged rather than
            // silently assumed to be correct.
            async let categoriesResult = fetchCategoriesUseCase(id: "")
            async let brandsResult = fetchBrandListUseCase()
            categories = try await categoriesResult
            brands = try await brandsResult
            await loadProducts()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func selectCategory(_ id: String?) async {
        selectedCategoryId = id
        await loadProducts()
    }

    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        do {
            products = try await fetchProductListUseCase(category: selectedCategoryId)
            let urls = products.compactMap { $0.imageURL }.compactMap(URL.init(string:))
            await imageLoading.prefetch(urls)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
