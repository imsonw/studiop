import Dependencies
import Foundation
import Security

/// Persists the auth token. This is the only type in the codebase allowed to touch Keychain for
/// the token — see docs/api-reference.md -> Auth mechanism.
protocol KeychainStoring: Sendable {
    func readToken() -> String?
    func writeToken(_ token: String)
    /// Removes the token synchronously, for use by `NetworkClient`'s 401/403 handler.
    func clear()
}

final class KeychainStore: KeychainStoring {
    private let service: String
    private let account = "authToken"

    init(service: String = Bundle.main.bundleIdentifier ?? "studiop") {
        self.service = service
    }

    func readToken() -> String? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    func writeToken(_ token: String) {
        let data = Data(token.utf8)
        let query = baseQuery()
        let updateStatus = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)

        if updateStatus == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData as String] = data
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }

    func clear() {
        SecItemDelete(baseQuery() as CFDictionary)
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}

/// In-memory stand-in for tests and SwiftUI previews — never touches the real Keychain.
final class InMemoryKeychainStore: KeychainStoring, @unchecked Sendable {
    private let lock = NSLock()
    private var token: String?

    func readToken() -> String? {
        lock.lock()
        defer { lock.unlock() }
        return token
    }

    func writeToken(_ token: String) {
        lock.lock()
        defer { lock.unlock() }
        self.token = token
    }

    func clear() {
        lock.lock()
        defer { lock.unlock() }
        token = nil
    }
}

private enum KeychainStoreKey: DependencyKey {
    static let liveValue: KeychainStoring = KeychainStore()
    static let testValue: KeychainStoring = InMemoryKeychainStore()
    static let previewValue: KeychainStoring = InMemoryKeychainStore()
}

extension DependencyValues {
    var keychainStore: KeychainStoring {
        get { self[KeychainStoreKey.self] }
        set { self[KeychainStoreKey.self] = newValue }
    }
}
