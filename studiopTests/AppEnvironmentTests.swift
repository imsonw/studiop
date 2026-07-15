import Foundation
import Testing
@testable import studiop

struct AppEnvironmentTests {
    @Test func startsAtItsInitialValue() {
        let store = EnvironmentStore(initial: .staging)
        #expect(store.current == .staging)
    }

    @Test func remoteConfigOverridesReplaceOnlyTheGivenFields() {
        let store = EnvironmentStore(initial: .staging)
        let overrideURL = URL(string: "https://overridden.example/api")!

        store.applyRemoteConfigOverrides(apiBaseURL: overrideURL)

        #expect(store.current.apiBaseURL == overrideURL)
        #expect(store.current.firebaseRealtimeDatabaseURL == AppEnvironment.staging.firebaseRealtimeDatabaseURL)
    }

    // Always a throwaway temp path, unique per test run — must never be
    // `AppEnvironment.localConfigURL` (the real, developer-machine file), since these tests
    // create/delete whatever's at this path.
    private static func makeTempConfigURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("local-environment-test-\(UUID().uuidString).json")
    }

    @Test func localIsNilWhenNoOverrideFileExists() {
        let tempURL = Self.makeTempConfigURL()
        #expect(AppEnvironment.local(configURL: tempURL) == nil)
    }

    @Test func localReadsTheGitignoredOverrideFileWhenPresent() throws {
        let tempURL = Self.makeTempConfigURL()
        let json = """
        {"apiBaseURL": "http://192.168.1.42:3000/api", "firebaseRealtimeDatabaseURL": "http://192.168.1.42:9000"}
        """
        try json.write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let local = try #require(AppEnvironment.local(configURL: tempURL))
        #expect(local.kind == .local)
        #expect(local.apiBaseURL == URL(string: "http://192.168.1.42:3000/api")!)
        #expect(local.firebaseRealtimeDatabaseURL == URL(string: "http://192.168.1.42:9000")!)
    }
}
