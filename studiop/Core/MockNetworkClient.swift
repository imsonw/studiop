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

    func send(_ request: NetworkRequest) async throws -> Data {
        try await Task.sleep(nanoseconds: Self.simulatedLatencyNanoseconds)

        let body = decodedBody(request.body)

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
