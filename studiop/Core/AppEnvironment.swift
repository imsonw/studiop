import Dependencies
import Foundation

/// The single source of truth for the backend API base URL and the Firebase Realtime Database
/// URL. No other file in the codebase may hardcode either — see docs/api-reference.md ->
/// Base configuration.
///
/// Named `AppEnvironment` (not `Environment`) to avoid colliding with SwiftUI's
/// `@Environment` property wrapper, which lives in the same module namespace.
struct AppEnvironment: Sendable, Equatable {
    enum Kind: String, Sendable {
        case local
        case staging
        case production
    }

    let kind: Kind
    var apiBaseURL: URL
    var firebaseRealtimeDatabaseURL: URL
}

extension AppEnvironment {
    // TODO: replace with the literal staging/prod values from the Flutter client's
    // `lib/config.dart` (see docs/api-reference.md -> Base configuration) before shipping.
    static let staging = AppEnvironment(
        kind: .staging,
        apiBaseURL: URL(string: "https://staging.PLACEHOLDER-BACKEND-DOMAIN.example/api")!,
        firebaseRealtimeDatabaseURL: URL(string: "https://PLACEHOLDER-staging-default-rtdb.firebaseio.com")!
    )

    static let production = AppEnvironment(
        kind: .production,
        apiBaseURL: URL(string: "https://service.PLACEHOLDER-BACKEND-DOMAIN-ALT.example/api")!,
        firebaseRealtimeDatabaseURL: URL(string: "https://PLACEHOLDER-prod-default-rtdb.firebaseio.com")!
    )

    /// The real, developer-machine-only override file this app reads at runtime — a sibling of
    /// this source file. Exposed separately from `local` so tests can point `local(configURL:)`
    /// at a throwaway temp file instead of ever touching this real path.
    static var localConfigURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("local-environment.json")
    }

    /// Personal, developer-machine-only backend override — read from a gitignored JSON file
    /// sitting next to this source file (see `local-environment.example.json` for the shape).
    /// `nil` when that file doesn't exist, so every other developer's build is unaffected.
    static var local: AppEnvironment? {
        local(configURL: localConfigURL)
    }

    static func local(configURL: URL) -> AppEnvironment? {
        struct LocalConfig: Decodable {
            let apiBaseURL: String
            let firebaseRealtimeDatabaseURL: String?
        }

        guard
            let data = try? Data(contentsOf: configURL),
            let config = try? JSONDecoder().decode(LocalConfig.self, from: data),
            let apiURL = URL(string: config.apiBaseURL)
        else {
            return nil
        }

        return AppEnvironment(
            kind: .local,
            apiBaseURL: apiURL,
            firebaseRealtimeDatabaseURL: config.firebaseRealtimeDatabaseURL.flatMap(URL.init)
                ?? AppEnvironment.staging.firebaseRealtimeDatabaseURL
        )
    }
}

/// Holds the current `AppEnvironment` and lets it be re-resolved after a Firebase Remote Config
/// fetch (`api_domain_staging`/`api_domain_prod`-style overrides), rather than being a
/// compile-time constant. Thread-safe: `NetworkClient` reads `current` on every request.
final class EnvironmentStore: @unchecked Sendable {
    private let lock = NSLock()
    private var _current: AppEnvironment

    init(initial: AppEnvironment) {
        self._current = initial
    }

    var current: AppEnvironment {
        lock.lock()
        defer { lock.unlock() }
        return _current
    }

    func applyRemoteConfigOverrides(apiBaseURL: URL? = nil, firebaseRealtimeDatabaseURL: URL? = nil) {
        lock.lock()
        defer { lock.unlock() }
        if let apiBaseURL {
            _current.apiBaseURL = apiBaseURL
        }
        if let firebaseRealtimeDatabaseURL {
            _current.firebaseRealtimeDatabaseURL = firebaseRealtimeDatabaseURL
        }
    }
}

private enum EnvironmentStoreKey: DependencyKey {
    static let liveValue: EnvironmentStore = {
        #if DEBUG
        EnvironmentStore(initial: .local ?? .staging)
        #else
        EnvironmentStore(initial: .production)
        #endif
    }()

    static let testValue = EnvironmentStore(initial: .staging)
    static let previewValue = EnvironmentStore(initial: .staging)
}

extension DependencyValues {
    var environmentStore: EnvironmentStore {
        get { self[EnvironmentStoreKey.self] }
        set { self[EnvironmentStoreKey.self] = newValue }
    }
}
