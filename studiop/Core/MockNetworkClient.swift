import Foundation

/// Serves canned/stateful JSON for every endpoint currently implemented (Auth, User, Biometric,
/// Address), instead of hitting the real backend. Swapped in at `NetworkClientKey.liveValue`
/// below — this is exactly the "even the backend can be swapped by changing one binding" goal
/// docs/architecture.md already commits to: no RepositoryImpl, DTO, UseCase, or View changes were
/// needed to make this switch, since they only ever depend on the `NetworkClient` protocol.
///
/// To go back to the real backend, swap `NetworkClientKey.liveValue`'s body back to
/// `URLSessionNetworkClient` (left fully intact below, just unreferenced).
///
/// **Maintenance note:** only the four domains implemented so far are mocked here. When a later
/// sprint adds a new RepositoryImpl (Notification, Stream, Store, ...), add its endpoints' cases
/// here too — an unmocked path fails loudly (`NetworkError.transport`) rather than silently
/// returning something wrong, same discipline as `UnimplementedAuthRepository` elsewhere.
actor MockNetworkClient: NetworkClient {
    /// Simulated latency so loading states are actually visible — tune or remove freely.
    private static let simulatedLatencyNanoseconds: UInt64 = 300_000_000

    private var user: [String: Any] = [
        "id": 1,
        "id_encode": 100_001,
        "name": "Mock User",
        "email": "mock.user@example.com",
        "phone": "0123456789",
        "avatar": NSNull(),
        "company_name": NSNull(),
        "tax_code": NSNull(),
        "social_provider": NSNull(),
    ]

    private var addresses: [[String: Any]] = [
        [
            "id": 1,
            "full_name": "Mock User",
            "phone": "0123456789",
            "address": "123 Mock Street",
            "house_number": "1",
            "postal_code": "700000",
            "location": "Da Nang, Vietnam",
            "country": "Vietnam",
            "is_default": true,
        ],
    ]

    private var nextAddressID = 2
    private var biometricEnabledDeviceIDs: Set<String> = []

    // Every entry carries BOTH the full-detail shape (`ProductDTO`: images/price_tiers/...) AND
    // the list-item shape (`ProductSummaryDTO`: singular image/price) so the same canned array can
    // serve `/stores/product/{id}` as well as `/stores/product/list|popular|best-selling` and
    // zones, without keeping two separate mock representations in sync.
    private var products: [[String: Any]] = [
        [
            "id_encode": "p1", "name": "Mock Sneakers",
            "images": ["https://example.com/p1.jpg"], "image": "https://example.com/p1.jpg",
            "description": "Comfortable everyday sneakers.",
            "price_tiers": [["price_type": "retail", "price": 49.99]], "price": 49.99,
            "rating": 4.5, "rating_count": 21, "category_id": "c1", "category_name": "Shoes",
            "brand_id": "b1", "brand_name": "Mock Brand", "stock": 12, "is_mall": false,
        ],
        [
            "id_encode": "p2", "name": "Mock Backpack",
            "images": ["https://example.com/p2.jpg"], "image": "https://example.com/p2.jpg",
            "description": "Durable everyday backpack.",
            "price_tiers": [["price_type": "retail", "price": 29.99]], "price": 29.99,
            "rating": 4.0, "rating_count": 8, "category_id": "c2", "category_name": "Bags",
            "brand_id": "b1", "brand_name": "Mock Brand", "stock": 5, "is_mall": true,
        ],
    ]
    private var cart: [[String: Any]] = []
    private var nextCheckoutID = 1
    private var checkoutSessions: [String: [String: Any]] = [:]
    private var studios: [[String: Any]] = [
        ["id_encode": "s1", "name": "Mock Studio", "follower_count": 120, "like_count": 45,
         "is_following": false, "is_liked": false],
    ]

    func send(_ request: NetworkRequest) async throws -> Data {
        try await Task.sleep(nanoseconds: Self.simulatedLatencyNanoseconds)

        let body = decodedBody(request.body)
        let formBody = decodedFormBody(request.body)

        switch (request.method, request.path) {
        case (.post, "users/register"):
            return try genericEnvelope(
                message: "Registration successful. Please check your email to verify your account."
            )

        case (.post, "users/login"), (.post, "users/socials"):
            return try authSessionEnvelope(token: "mock-token-\(UUID().uuidString.prefix(8))")

        case (.post, "v1/biometric/login"):
            return try JSONSerialization.data(withJSONObject: [
                "status": 1,
                "code": "U200",
                "msg": "Logged in successfully.",
                "data": user,
                "token": "mock-token-\(UUID().uuidString.prefix(8))",
                "new_biometric_token": "mock-biometric-token-\(UUID().uuidString.prefix(8))",
            ])

        case (.post, "users/verify/account"):
            return try genericEnvelope(message: "Account verified.")

        case (.post, "users/reset/password"):
            return try genericEnvelope(message: "Password reset email sent.")

        case (.post, "users/reset/password/confirm"):
            return try genericEnvelope(message: "Password has been reset.")

        case (.get, "users/info"):
            return try dataEnvelope(user)

        case (.post, "users/change/password"):
            return try genericEnvelope(message: "Password changed.")

        case (.post, "users/change/info"), (.post, "users/change/profile"):
            for (key, value) in body {
                user[key] = value
            }
            return try dataEnvelope(user)

        case (.post, "users/change/address"):
            return try genericEnvelope(message: "Address updated.")

        case (.post, "users/request_remove"):
            return try genericEnvelope(message: "Removal requested. Check your email for a confirmation code.")

        case (.post, "users/request_remove/confirm"):
            return try genericEnvelope(message: "Account removed.")

        case (.post, "v1/biometric/enable"):
            if let deviceID = body["device_id"] as? String {
                biometricEnabledDeviceIDs.insert(deviceID)
            }
            return try JSONSerialization.data(withJSONObject: [
                "status": 1,
                "code": "U000",
                "msg": "Biometric login enabled.",
                "biometric_token": "mock-biometric-token-\(UUID().uuidString.prefix(8))",
            ])

        case (.post, "v1/biometric/disable"):
            if let deviceID = body["device_id"] as? String {
                biometricEnabledDeviceIDs.remove(deviceID)
            }
            return try genericEnvelope(message: "Biometric login disabled.")

        case (.get, "v1/biometric/check-status"):
            let deviceID = request.queryItems.first { $0.name == "device_id" }?.value ?? ""
            return try dataEnvelope([
                "device_id": deviceID,
                "device_name": "Mock Device",
                "is_enabled": biometricEnabledDeviceIDs.contains(deviceID),
            ])

        case (.get, "users/address"):
            return try dataEnvelope(addresses)

        case (.post, "users/address/store"):
            var newAddress = body
            newAddress["id"] = nextAddressID
            nextAddressID += 1
            if newAddress["is_default"] as? Bool == true {
                unsetDefaultOnAllAddresses()
            }
            addresses.append(newAddress)
            return try dataEnvelope(newAddress)

        case (.post, let path) where path.hasPrefix("users/address/update/"):
            guard let id = Int(path.dropFirst("users/address/update/".count)) else {
                throw NetworkError.invalidURL
            }
            var updated = body
            updated["id"] = id
            if updated["is_default"] as? Bool == true {
                unsetDefaultOnAllAddresses()
            }
            if let index = addresses.firstIndex(where: { $0["id"] as? Int == id }) {
                addresses[index] = updated
            } else {
                addresses.append(updated)
            }
            return try dataEnvelope(updated)

        case (.post, let path) where path.hasPrefix("users/address/delete/"):
            guard let id = Int(path.dropFirst("users/address/delete/".count)) else {
                throw NetworkError.invalidURL
            }
            addresses.removeAll { $0["id"] as? Int == id }
            return try genericEnvelope(message: "Address deleted.")

        case (.get, "stores/settings/filters"), (.get, "stores/detail"):
            return try dataEnvelope([
                "store_id": "store1", "store_name": "Mock Store", "rating": 4.6,
                "price_range": ["min_price": 9.99, "max_price": 99.99],
                "categories": mockCategories, "brands": mockBrands, "sort_options": ["newest", "price_asc"],
            ])

        case (.get, "stores/categories"):
            return try dataEnvelope(mockCategories)

        case (.get, "stores/settings/homepage"), (.get, "stores/studio/homepage-zones"):
            return try dataEnvelope([
                "zones": [["id_encode": "z1", "title": "Popular", "type": "popular", "products": products]],
            ])

        case (.get, "stores/product/popular"), (.get, "stores/product/best-selling"):
            return try dataEnvelope(products)

        case (.get, "stores/product/list"):
            let query = request.queryItems.first { $0.name == "q" }?.value?.lowercased()
            let filtered = query.map { q in
                products.filter { ($0["name"] as? String)?.lowercased().contains(q) == true }
            } ?? products
            return try dataEnvelope(filtered)

        case (.get, let path) where path.hasPrefix("stores/product/") && path.hasSuffix("/related"):
            return try dataEnvelope(products)

        case (.get, let path) where path.hasPrefix("stores/product/"):
            let idEncode = String(path.dropFirst("stores/product/".count))
            guard let product = products.first(where: { $0["id_encode"] as? String == idEncode }) else {
                throw NetworkError.transport("MockNetworkClient: no product '\(idEncode)'")
            }
            return try dataEnvelope(product)

        case (.get, "stores/brand/list"):
            return try dataEnvelope(mockBrands)

        case (.post, "stores/checkout/buy-now"):
            let productId = body["product_id"] as? String ?? ""
            let quantity = Int(body["quantity"] as? String ?? "") ?? (body["quantity"] as? Int) ?? 1
            return try dataEnvelope(makeCheckoutSession(productIds: [productId], quantity: quantity))

        case (.post, "stores/cart/add"):
            let productId = body["product_id"] as? String ?? ""
            let quantity = Int(body["quantity"] as? String ?? "") ?? (body["quantity"] as? Int) ?? 1
            let priceType = body["price_type"] as? String ?? "retail"
            let item = cartItem(productId: productId, quantity: quantity, priceType: priceType)
            cart.removeAll { $0["product_id"] as? String == productId }
            cart.append(item)
            return try dataEnvelope(item)

        case (.post, "stores/cart/list"):
            return try dataEnvelope(cart)

        case (.post, "stores/cart/count"):
            return try dataEnvelope(cart.count)

        case (.post, "stores/cart/update"):
            let productId = body["product_id"] as? String ?? ""
            let quantity = Int(body["quantity"] as? String ?? "") ?? (body["quantity"] as? Int) ?? 1
            let priceType = (cart.first { $0["product_id"] as? String == productId }?["price_type"] as? String) ?? "retail"
            let item = cartItem(productId: productId, quantity: quantity, priceType: priceType)
            if let index = cart.firstIndex(where: { $0["product_id"] as? String == productId }) {
                cart[index] = item
            } else {
                cart.append(item)
            }
            return try dataEnvelope(item)

        case (.post, "stores/cart/remove"):
            let productId = body["product_id"] as? String ?? ""
            cart.removeAll { $0["product_id"] as? String == productId }
            return try genericEnvelope(message: "Removed from cart.")

        case (.post, "stores/cart/clear"):
            cart.removeAll()
            return try genericEnvelope(message: "Cart cleared.")

        case (.post, "stores/checkout/update-address"):
            let id = request.queryItems.first { $0.name == "id" }?.value ?? ""
            let addressId: Any = request.queryItems.first { $0.name == "address_id" }?.value ?? NSNull()
            checkoutSessions[id]?["address_id"] = addressId
            return try dataEnvelope(checkoutSessions[id] ?? [:])

        case (.post, "stores/checkout/create"):
            let itemIds = (formBody["items"] ?? "").split(separator: ",").map(String.init)
            return try dataEnvelope(makeCheckoutSession(productIds: itemIds, quantity: nil))

        case (.post, "stores/checkout/get"):
            let id = formBody["id"] ?? ""
            return try dataEnvelope(checkoutSessions[id] ?? [:])

        case (.post, "stores/checkout/process"):
            let id = formBody["id"] ?? ""
            let paymentMethod = formBody["payment_method"] ?? "bank_transfer"
            return try dataEnvelope(orderPayload(id: id, status: "processing", paymentMethod: paymentMethod))

        case (.get, "stores/checkout/success"):
            let id = request.queryItems.first { $0.name == "id" }?.value ?? ""
            return try dataEnvelope(orderPayload(id: id, status: "completed", paymentMethod: "bank_transfer"))

        case (.post, "studios/interactions"):
            let id = request.queryItems.first { $0.name == "id" }?.value ?? ""
            let type = request.queryItems.first { $0.name == "type" }?.value ?? ""
            if let index = studios.firstIndex(where: { $0["id_encode"] as? String == id }) {
                if type == "follow" {
                    let current = studios[index]["is_following"] as? Bool ?? false
                    studios[index]["is_following"] = !current
                } else if type == "like" {
                    let current = studios[index]["is_liked"] as? Bool ?? false
                    studios[index]["is_liked"] = !current
                }
            }
            return try genericEnvelope(message: "OK")

        case (.get, "studios/list/interaction"):
            return try dataEnvelope(studios)

        case (.get, "studios/list/interaction/filters"):
            return try dataEnvelope([
                ["type": "all", "label": "All"],
                ["type": "follow", "label": "Following"],
                ["type": "like", "label": "Liked"],
                ["type": "top_rated", "label": "Top Rated"],
            ])

        default:
            throw NetworkError.transport(
                "MockNetworkClient: no mock configured for \(request.method.rawValue) \(request.path) " +
                "-- add a case in Core/MockNetworkClient.swift."
            )
        }
    }

    private func unsetDefaultOnAllAddresses() {
        addresses = addresses.map { address in
            var address = address
            address["is_default"] = false
            return address
        }
    }

    private func decodedBody(_ body: Data?) -> [String: Any] {
        guard let body, let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] else {
            return [:]
        }
        return json
    }

    /// Decodes `application/x-www-form-urlencoded` bodies -- `StoreRepository`'s checkout calls
    /// use this encoding (documented as "FormData"), not JSON. See `NetworkRequest.BodyEncoding`.
    private func decodedFormBody(_ body: Data?) -> [String: String] {
        guard let body, let string = String(data: body, encoding: .utf8) else { return [:] }
        var result: [String: String] = [:]
        for pair in string.split(separator: "&") {
            let parts = pair.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { continue }
            result[String(parts[0])] = String(parts[1]).removingPercentEncoding ?? String(parts[1])
        }
        return result
    }

    private var mockCategories: [[String: Any]] {
        [
            ["id_encode": "c1", "name": "Shoes", "image": NSNull(), "parent_id": NSNull(), "children": []],
            ["id_encode": "c2", "name": "Bags", "image": NSNull(), "parent_id": NSNull(), "children": []],
        ]
    }

    private var mockBrands: [[String: Any]] {
        [["id_encode": "b1", "name": "Mock Brand", "logo": NSNull()]]
    }

    private func cartItem(productId: String, quantity: Int, priceType: String) -> [String: Any] {
        let product = products.first { $0["id_encode"] as? String == productId }
        let priceTiers = product?["price_tiers"] as? [[String: Any]]
        let price = priceTiers?.first { $0["price_type"] as? String == priceType }?["price"]
            ?? priceTiers?.first?["price"] ?? 0
        return [
            "product_id": productId, "quantity": quantity, "price_type": priceType,
            "product_name": product?["name"] ?? "", "product_image": (product?["images"] as? [String])?.first ?? NSNull(),
            "unit_price": price,
        ]
    }

    private func orderPayload(id: String, status: String, paymentMethod: String) -> [String: Any] {
        let session = checkoutSessions[id] ?? [:]
        var payload: [String: Any] = [:]
        payload["id_encode"] = id
        payload["code"] = "ORD-\(id)"
        payload["status"] = status
        payload["created_at"] = "2026-07-23 00:00:00"
        payload["items"] = session["items"] ?? []
        payload["subtotal"] = session["subtotal"] ?? 0
        payload["shipping_fee"] = session["shipping_fee"] ?? 0
        payload["discount"] = session["discount"] ?? 0
        payload["total"] = session["total"] ?? 0
        payload["address_id"] = session["address_id"] ?? NSNull()
        payload["payment_method"] = paymentMethod
        return payload
    }

    private func makeCheckoutSession(productIds: [String], quantity: Int?) -> [String: Any] {
        let id = String(nextCheckoutID)
        nextCheckoutID += 1

        let items: [[String: Any]] = productIds.map { productId in
            let cartMatch = cart.first { $0["product_id"] as? String == productId }
            let product = products.first { $0["id_encode"] as? String == productId }
            let priceTiers = product?["price_tiers"] as? [[String: Any]]
            let unitPrice = priceTiers?.first?["price"] ?? 0
            return [
                "product_id": productId,
                "product_name": product?["name"] ?? "",
                "quantity": cartMatch?["quantity"] ?? quantity ?? 1,
                "price_type": "retail",
                "unit_price": unitPrice,
            ]
        }
        let subtotal = items.reduce(0.0) { partial, item in
            let unitPrice = item["unit_price"] as? Double ?? 0
            let itemQuantity = item["quantity"] as? Int ?? 1
            return partial + unitPrice * Double(itemQuantity)
        }
        let session: [String: Any] = [
            "id_encode": id, "items": items, "subtotal": subtotal, "shipping_fee": 4.99,
            "discount": 0, "total": subtotal + 4.99, "address_id": NSNull(),
            "payment_method": NSNull(), "status": "pending",
        ]
        checkoutSessions[id] = session
        return session
    }

    private func genericEnvelope(message: String) throws -> Data {
        try JSONSerialization.data(withJSONObject: ["status": 1, "code": "U000", "msg": message])
    }

    private func dataEnvelope(_ payload: Any) throws -> Data {
        try JSONSerialization.data(withJSONObject: ["status": 1, "code": "U000", "msg": "OK", "data": payload])
    }

    private func authSessionEnvelope(token: String) throws -> Data {
        try JSONSerialization.data(withJSONObject: [
            "status": 1,
            "code": "U200",
            "msg": "Logged in successfully.",
            "data": user,
            "token": token,
        ])
    }
}
