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
}
