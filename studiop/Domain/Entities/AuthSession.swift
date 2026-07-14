import Foundation

/// The shared Domain-level result of register/login/social-login: a `User` plus the auth token
/// string. Where the token gets persisted (Keychain) is Core's concern, not this entity's.
struct AuthSession: Equatable, Sendable {
    var user: User
    var token: String

    init(user: User, token: String) {
        self.user = user
        self.token = token
    }
}
