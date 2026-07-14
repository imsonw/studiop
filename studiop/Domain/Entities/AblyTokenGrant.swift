import Foundation

/// Ably token issuance result, per `POST /chat/broadcasting/auth`. Still a REST-only shape —
/// the Ably SDK usage that consumes this token is built in a later sprint.
struct AblyTokenGrant: Equatable {
    let token: String
    let ttlSeconds: Int
}
