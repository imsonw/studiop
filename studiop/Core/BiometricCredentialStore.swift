import Dependencies
import Foundation
import Security

/// Persists the device_id/biometric_token pairing from `/v1/biometric/enable` — a secret, same
/// category as the auth token, so Keychain rather than UserDefaults/SwiftData. Separate from
/// `KeychainStoring` (which is narrowly scoped to the single auth-token account) rather than
/// extending it — one protocol per distinct capability, same convention as `BiometricAuthenticating`.
protocol BiometricCredentialStoring: Sendable {
    func read() -> (deviceID: String, biometricToken: String)?
    func write(deviceID: String, biometricToken: String)
    func clear()
}

final class BiometricCredentialStore: BiometricCredentialStoring {
    private let service: String
    private let deviceIDAccount = "biometricDeviceID"
    private let tokenAccount = "biometricToken"

    init(service: String = Bundle.main.bundleIdentifier ?? "studiop") {
        self.service = service
    }

    func read() -> (deviceID: String, biometricToken: String)? {
        guard
            let deviceID = readString(account: deviceIDAccount),
            let biometricToken = readString(account: tokenAccount)
        else {
            return nil
        }
        return (deviceID, biometricToken)
    }

    func write(deviceID: String, biometricToken: String) {
        writeString(deviceID, account: deviceIDAccount)
        writeString(biometricToken, account: tokenAccount)
    }

    func clear() {
        SecItemDelete(baseQuery(account: deviceIDAccount) as CFDictionary)
        SecItemDelete(baseQuery(account: tokenAccount) as CFDictionary)
    }

    private func readString(account: String) -> String? {
        var query = baseQuery(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    private func writeString(_ value: String, account: String) {
        let data = Data(value.utf8)
        let query = baseQuery(account: account)
        let updateStatus = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)

        if updateStatus == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData as String] = data
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }

    private func baseQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}

/// In-memory stand-in for previews — never touches the real Keychain.
final class InMemoryBiometricCredentialStore: BiometricCredentialStoring, @unchecked Sendable {
    private let lock = NSLock()
    private var pairing: (deviceID: String, biometricToken: String)?

    func read() -> (deviceID: String, biometricToken: String)? {
        lock.lock()
        defer { lock.unlock() }
        return pairing
    }

    func write(deviceID: String, biometricToken: String) {
        lock.lock()
        defer { lock.unlock() }
        pairing = (deviceID, biometricToken)
    }

    func clear() {
        lock.lock()
        defer { lock.unlock() }
        pairing = nil
    }
}

private enum BiometricCredentialStoreKey: DependencyKey {
    static let liveValue: BiometricCredentialStoring = BiometricCredentialStore()
    static let testValue: BiometricCredentialStoring = InMemoryBiometricCredentialStore()
    static let previewValue: BiometricCredentialStoring = InMemoryBiometricCredentialStore()
}

extension DependencyValues {
    var biometricCredentialStore: BiometricCredentialStoring {
        get { self[BiometricCredentialStoreKey.self] }
        set { self[BiometricCredentialStoreKey.self] = newValue }
    }
}
