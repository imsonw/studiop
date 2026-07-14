import Foundation
import Testing
@testable import studiop

struct KeychainStoreTests {
    @Test func writeThenReadReturnsTheSameToken() {
        let store = KeychainStore(service: "studiop.tests.\(UUID().uuidString)")
        defer { store.clear() }

        store.writeToken("token-1")

        #expect(store.readToken() == "token-1")
    }

    @Test func writeOverwritesAnExistingToken() {
        let store = KeychainStore(service: "studiop.tests.\(UUID().uuidString)")
        defer { store.clear() }

        store.writeToken("token-1")
        store.writeToken("token-2")

        #expect(store.readToken() == "token-2")
    }

    @Test func clearRemovesTheTokenSynchronously() {
        let store = KeychainStore(service: "studiop.tests.\(UUID().uuidString)")

        store.writeToken("token-1")
        store.clear()

        #expect(store.readToken() == nil)
    }

    @Test func readReturnsNilWhenNothingWasEverWritten() {
        let store = KeychainStore(service: "studiop.tests.\(UUID().uuidString)")

        #expect(store.readToken() == nil)
    }
}
