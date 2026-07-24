import Foundation

@MainActor
@Observable
final class ProductDetailViewModel {
    private(set) var product: Product?
    private(set) var relatedProducts: [ProductSummary] = []
    var isLoading = false
    var errorMessage: String?
    var isAddingToCart = false
    var cartMessage: String?

    private let idEncode: String
    private let fetchProductDetailUseCase: FetchProductDetailUseCase
    private let fetchRelatedProductsUseCase: FetchRelatedProductsUseCase
    private let addToCartUseCase: AddToCartUseCase
    private let buyNowUseCase: BuyNowUseCase
    private let imageLoading: ImageLoading

    init(
        idEncode: String,
        fetchProductDetailUseCase: FetchProductDetailUseCase,
        fetchRelatedProductsUseCase: FetchRelatedProductsUseCase,
        addToCartUseCase: AddToCartUseCase,
        buyNowUseCase: BuyNowUseCase,
        imageLoading: ImageLoading
    ) {
        self.idEncode = idEncode
        self.fetchProductDetailUseCase = fetchProductDetailUseCase
        self.fetchRelatedProductsUseCase = fetchRelatedProductsUseCase
        self.addToCartUseCase = addToCartUseCase
        self.buyNowUseCase = buyNowUseCase
        self.imageLoading = imageLoading
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let product = try await fetchProductDetailUseCase(idEncode: idEncode)
            self.product = product
            // Image carousel prefetch -- the TaskGroup/actor-based loader (senior-skill add-on,
            // see Core/ImageLoading.swift) warms every carousel image at once instead of each
            // page triggering its own independent download as the user swipes.
            let urls = product.images.compactMap(URL.init(string:))
            await imageLoading.prefetch(urls)

            relatedProducts = try await fetchRelatedProductsUseCase(idEncode: idEncode, limit: 10, page: 1)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func addToCart(priceType: String, quantity: Int) async {
        isAddingToCart = true
        cartMessage = nil
        do {
            _ = try await addToCartUseCase(productId: idEncode, quantity: quantity, priceType: priceType)
            cartMessage = "Added to cart."
        } catch {
            errorMessage = error.localizedDescription
        }
        isAddingToCart = false
    }

    func buyNow(priceType: String, quantity: Int) async -> CheckoutSession? {
        isAddingToCart = true
        errorMessage = nil
        defer { isAddingToCart = false }
        do {
            return try await buyNowUseCase(productId: idEncode, quantity: quantity, priceType: priceType)
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
