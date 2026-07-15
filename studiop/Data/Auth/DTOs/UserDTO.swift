import Foundation

/// The `/users/info` response shape, and the nested `data` object in the auth session response.
/// `idEncode` confirmed as a JSON number (not string) against a real captured `/users/login`
/// response — `User.idEncode` (Domain) stays `String`, since Domain doesn't mirror backend JSON
/// types exactly; the conversion happens in `toDomain()`.
struct UserDTO: Decodable {
    let id: Int
    let idEncode: Int
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
            idEncode: String(idEncode),
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
