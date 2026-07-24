import Foundation

/// All `StoreRepository` calls use `.userToken` (`NetworkRequest`'s default) — none of
/// `/stores/*` is documented as a public-token endpoint, unlike Biometric's login call.
final class StoreRepositoryImpl: StoreRepository {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    func fetchStoreFilterSettings(storeId: String) async throws -> StoreSettings {
        let data = try await networkClient.send(
            NetworkRequest(path: "stores/settings/filters", queryItems: [URLQueryItem(name: "id", value: storeId)])
        )
        return try JSONDecoder().decode(DataResponseDTO<StoreSettingsDTO>.self, from: data).data.toDomain()
    }

    func fetchStoreDetail(id: String) async throws -> StoreSettings {
        let data = try await networkClient.send(
            NetworkRequest(path: "stores/detail", queryItems: [URLQueryItem(name: "id", value: id)])
        )
        return try JSONDecoder().decode(DataResponseDTO<StoreSettingsDTO>.self, from: data).data.toDomain()
    }

    func fetchCategories(id: String) async throws -> [ProductCategory] {
        let data = try await networkClient.send(
            NetworkRequest(path: "stores/categories", queryItems: [URLQueryItem(name: "id", value: id)])
        )
        return try JSONDecoder().decode(DataResponseDTO<[ProductCategoryDTO]>.self, from: data).data.map { $0.toDomain() }
    }

    func fetchHomepageSettings() async throws -> StoreSettings {
        let data = try await networkClient.send(NetworkRequest(path: "stores/settings/homepage"))
        return try JSONDecoder().decode(DataResponseDTO<StoreSettingsDTO>.self, from: data).data.toDomain()
    }

    func fetchHomepageZones(storeId: String) async throws -> StoreSettings {
        let data = try await networkClient.send(
            NetworkRequest(
                path: "stores/studio/homepage-zones",
                queryItems: [URLQueryItem(name: "id", value: storeId)]
            )
        )
        return try JSONDecoder().decode(DataResponseDTO<StoreSettingsDTO>.self, from: data).data.toDomain()
    }

    func fetchPopularProducts(
        limit: Int?,
        query: String?,
        category: String?,
        priceMin: Decimal?,
        priceMax: Decimal?
    ) async throws -> [ProductSummary] {
        let data = try await networkClient.send(
            NetworkRequest(
                path: "stores/product/popular",
                queryItems: Self.productFilterQueryItems(
                    limit: limit, query: query, category: category, priceMin: priceMin, priceMax: priceMax
                )
            )
        )
        return try JSONDecoder().decode(DataResponseDTO<[ProductSummaryDTO]>.self, from: data).data.map { $0.toDomain() }
    }

    func fetchBestSellingProducts(
        limit: Int?,
        query: String?,
        category: String?,
        priceMin: Decimal?,
        priceMax: Decimal?
    ) async throws -> [ProductSummary] {
        let data = try await networkClient.send(
            NetworkRequest(
                path: "stores/product/best-selling",
                queryItems: Self.productFilterQueryItems(
                    limit: limit, query: query, category: category, priceMin: priceMin, priceMax: priceMax
                )
            )
        )
        return try JSONDecoder().decode(DataResponseDTO<[ProductSummaryDTO]>.self, from: data).data.map { $0.toDomain() }
    }

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
    ) async throws -> [ProductSummary] {
        var queryItems = Self.productFilterQueryItems(
            limit: limit, query: query, category: category, priceMin: priceMin, priceMax: priceMax
        )
        queryItems += [
            page.map { URLQueryItem(name: "page", value: String($0)) },
            id.map { URLQueryItem(name: "id", value: $0) },
            minRating.map { URLQueryItem(name: "min_rating", value: String($0)) },
            sort.map { URLQueryItem(name: "sort", value: $0) },
            randomSeed.map { URLQueryItem(name: "random_seed", value: $0) },
            isMall.map { URLQueryItem(name: "is_mall", value: $0 ? "1" : "0") },
            brandId.map { URLQueryItem(name: "brand_id", value: $0) },
        ].compactMap { $0 }

        let data = try await networkClient.send(NetworkRequest(path: "stores/product/list", queryItems: queryItems))
        return try JSONDecoder().decode(DataResponseDTO<[ProductSummaryDTO]>.self, from: data).data.map { $0.toDomain() }
    }

    func fetchProductDetail(idEncode: String) async throws -> Product {
        let data = try await networkClient.send(NetworkRequest(path: "stores/product/\(idEncode)"))
        return try JSONDecoder().decode(DataResponseDTO<ProductDTO>.self, from: data).data.toDomain()
    }

    func fetchRelatedProducts(idEncode: String, limit: Int?, page: Int?) async throws -> [ProductSummary] {
        let queryItems = [
            limit.map { URLQueryItem(name: "limit", value: String($0)) },
            page.map { URLQueryItem(name: "page", value: String($0)) },
        ].compactMap { $0 }
        let data = try await networkClient.send(
            NetworkRequest(path: "stores/product/\(idEncode)/related", queryItems: queryItems)
        )
        return try JSONDecoder().decode(DataResponseDTO<[ProductSummaryDTO]>.self, from: data).data.map { $0.toDomain() }
    }

    func buyNow(productId: String, quantity: Int, priceType: String) async throws -> CheckoutSession {
        let dto = ["product_id": productId, "quantity": String(quantity), "price_type": priceType]
        let data = try await networkClient.send(
            NetworkRequest(
                path: "stores/checkout/buy-now",
                method: .post,
                body: try JSONEncoder().encode(dto)
            )
        )
        return try JSONDecoder().decode(DataResponseDTO<CheckoutSessionDTO>.self, from: data).data.toDomain()
    }

    func addToCart(productId: String, quantity: Int, priceType: String) async throws -> CartItem {
        let dto = ["product_id": productId, "quantity": String(quantity), "price_type": priceType]
        let data = try await networkClient.send(
            NetworkRequest(path: "stores/cart/add", method: .post, body: try JSONEncoder().encode(dto))
        )
        return try JSONDecoder().decode(DataResponseDTO<CartItemDTO>.self, from: data).data.toDomain()
    }

    func listCart() async throws -> [CartItem] {
        let data = try await networkClient.send(NetworkRequest(path: "stores/cart/list", method: .post))
        return try JSONDecoder().decode(DataResponseDTO<[CartItemDTO]>.self, from: data).data.map { $0.toDomain() }
    }

    func countCart() async throws -> Int {
        let data = try await networkClient.send(NetworkRequest(path: "stores/cart/count", method: .post))
        return try JSONDecoder().decode(DataResponseDTO<Int>.self, from: data).data
    }

    func updateCart(productId: String, quantity: Int) async throws -> CartItem {
        let dto = ["product_id": productId, "quantity": String(quantity)]
        let data = try await networkClient.send(
            NetworkRequest(path: "stores/cart/update", method: .post, body: try JSONEncoder().encode(dto))
        )
        return try JSONDecoder().decode(DataResponseDTO<CartItemDTO>.self, from: data).data.toDomain()
    }

    func removeFromCart(productId: String) async throws {
        let dto = ["product_id": productId]
        _ = try await networkClient.send(
            NetworkRequest(path: "stores/cart/remove", method: .post, body: try JSONEncoder().encode(dto))
        )
    }

    func clearCart() async throws {
        _ = try await networkClient.send(NetworkRequest(path: "stores/cart/clear", method: .post))
    }

    func updateCheckoutAddress(id: String, addressId: String) async throws -> CheckoutSession {
        let data = try await networkClient.send(
            NetworkRequest(
                path: "stores/checkout/update-address",
                method: .post,
                queryItems: [URLQueryItem(name: "id", value: id), URLQueryItem(name: "address_id", value: addressId)]
            )
        )
        return try JSONDecoder().decode(DataResponseDTO<CheckoutSessionDTO>.self, from: data).data.toDomain()
    }

    /// Body is `FormData`, not JSON — see docs/api-reference.md's `StoreRepository` table and
    /// `NetworkRequest.BodyEncoding`'s doc comment.
    func processCheckout(id: String, paymentMethod: String) async throws -> Order {
        let data = try await networkClient.send(
            NetworkRequest(
                path: "stores/checkout/process",
                method: .post,
                body: NetworkRequest.formURLEncodedBody(["id": id, "payment_method": paymentMethod]),
                bodyEncoding: .formURLEncoded
            )
        )
        return try JSONDecoder().decode(DataResponseDTO<OrderDTO>.self, from: data).data.toDomain()
    }

    /// Body is `FormData` with a comma-joined `items` string, not JSON — see
    /// docs/api-reference.md's `StoreRepository` table.
    func createCheckout(itemIds: [String]) async throws -> CheckoutSession {
        let data = try await networkClient.send(
            NetworkRequest(
                path: "stores/checkout/create",
                method: .post,
                body: NetworkRequest.formURLEncodedBody(["items": itemIds.joined(separator: ",")]),
                bodyEncoding: .formURLEncoded
            )
        )
        return try JSONDecoder().decode(DataResponseDTO<CheckoutSessionDTO>.self, from: data).data.toDomain()
    }

    /// Body is `FormData`, not JSON — see docs/api-reference.md's `StoreRepository` table.
    func getCheckout(id: String, priceType: String) async throws -> CheckoutSession {
        let data = try await networkClient.send(
            NetworkRequest(
                path: "stores/checkout/get",
                method: .post,
                body: NetworkRequest.formURLEncodedBody(["id": id, "price_type": priceType]),
                bodyEncoding: .formURLEncoded
            )
        )
        return try JSONDecoder().decode(DataResponseDTO<CheckoutSessionDTO>.self, from: data).data.toDomain()
    }

    func fetchCheckoutSuccess(id: String) async throws -> Order {
        let data = try await networkClient.send(
            NetworkRequest(path: "stores/checkout/success", queryItems: [URLQueryItem(name: "id", value: id)])
        )
        return try JSONDecoder().decode(DataResponseDTO<OrderDTO>.self, from: data).data.toDomain()
    }

    func fetchBrandList() async throws -> [Brand] {
        let data = try await networkClient.send(NetworkRequest(path: "stores/brand/list"))
        return try JSONDecoder().decode(DataResponseDTO<[BrandDTO]>.self, from: data).data.map { $0.toDomain() }
    }

    private static func productFilterQueryItems(
        limit: Int?,
        query: String?,
        category: String?,
        priceMin: Decimal?,
        priceMax: Decimal?
    ) -> [URLQueryItem] {
        [
            limit.map { URLQueryItem(name: "limit", value: String($0)) },
            query.map { URLQueryItem(name: "q", value: $0) },
            category.map { URLQueryItem(name: "category", value: $0) },
            priceMin.map { URLQueryItem(name: "price_min", value: "\($0)") },
            priceMax.map { URLQueryItem(name: "price_max", value: "\($0)") },
        ].compactMap { $0 }
    }
}
