import Dependencies
import Foundation

/// Lightweight cache for the logged-in user's profile, kept separate from the Keychain token —
/// mirrors the Flutter app's `token` / `user_info` SharedPreferences split. Stores raw encoded
/// bytes; the Domain-level `User` entity (Sprint 2) owns the encoding/decoding.
protocol UserProfileCaching: Sendable {
    func read() -> Data?
    func write(_ data: Data)
    func clear()
}

final class UserProfileCache: UserProfileCaching {
    private let defaults: UserDefaults
    private let key = "studiop.cachedUserProfile"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func read() -> Data? {
        defaults.data(forKey: key)
    }

    func write(_ data: Data) {
        defaults.set(data, forKey: key)
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }
}

/// In-memory stand-in for tests and SwiftUI previews.
final class InMemoryUserProfileCache: UserProfileCaching, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: Data?

    func read() -> Data? {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    func write(_ data: Data) {
        lock.lock()
        defer { lock.unlock() }
        storage = data
    }

    func clear() {
        lock.lock()
        defer { lock.unlock() }
        storage = nil
    }
}

private enum UserProfileCacheKey: DependencyKey {
    static let liveValue: UserProfileCaching = UserProfileCache()
    static let testValue: UserProfileCaching = InMemoryUserProfileCache()
    static let previewValue: UserProfileCaching = InMemoryUserProfileCache()
}

extension DependencyValues {
    var userProfileCache: UserProfileCaching {
        get { self[UserProfileCacheKey.self] }
        set { self[UserProfileCacheKey.self] = newValue }
    }
}
