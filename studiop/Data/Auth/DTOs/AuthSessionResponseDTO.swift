import Foundation

/// Response shape for register/login/social-login.
/// - Note: docs/api-reference.md documents these endpoints' request bodies but not the literal
///   response JSON — this `{token, user}` shape is a best guess pending backend confirmation.
struct AuthSessionResponseDTO: Decodable {
    let token: String
    let user: UserDTO

    func toDomain() -> AuthSession {
        AuthSession(user: user.toDomain(), token: token)
    }
}
