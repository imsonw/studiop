import Foundation

/// The `/users/info` response shape, and the nested `user` object in the auth session response.
/// - Note: docs/api-reference.md documents the endpoint but not the literal JSON field names —
///   this is a best-guess snake_case shape pending confirmation with the backend team.
struct UserDTO: Decodable {
    let id: Int
    let idEncode: String
    let name: String
    let email: String
    let phone: String?
    let avatar: String?
    let companyName: String?
    let taxCode: String?
    let socialProvider: String?

    enum CodingKeys: String, CodingKey {
        case id
        case idEncode = "id_encode"
        case name, email, phone, avatar
        case companyName = "company_name"
        case taxCode = "tax_code"
        case socialProvider = "social_provider"
    }

    func toDomain() -> User {
        User(
            id: id,
            idEncode: idEncode,
            name: name,
            email: email,
            phone: phone,
            avatarURL: avatar,
            companyName: companyName,
            taxCode: taxCode,
            socialProvider: socialProvider
        )
    }
}
