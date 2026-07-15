import Foundation

/// Response shape for register/login/social-login. Confirmed against a real captured
/// `/users/login` response (200, `{status, code, msg, data, token}`) — the user object is under
/// `data`, not `user`.
struct AuthSessionResponseDTO: Decodable {
    let token: String
    let data: UserDTO

    func toDomain() -> AuthSession {
        AuthSession(user: data.toDomain(), token: token)
    }
}
