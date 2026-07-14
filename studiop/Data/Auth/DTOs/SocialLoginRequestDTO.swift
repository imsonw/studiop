import Foundation

struct SocialLoginRequestDTO: Encodable {
    let social: String
    let socialToken: String
    let socialEmail: String?
    let socialUserId: String?
    let socialName: String?
    let socialAvatar: String?
    let authCode: String?
    let codeVerifier: String?
    let redirectURI: String?

    enum CodingKeys: String, CodingKey {
        case social
        case socialToken = "social_token"
        case socialEmail = "social_email"
        case socialUserId = "social_user_id"
        case socialName = "social_name"
        case socialAvatar = "social_avatar"
        case authCode = "auth_code"
        case codeVerifier = "code_verifier"
        case redirectURI = "redirect_uri"
    }
}
