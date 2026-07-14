import Foundation

/// Full-profile update body for `/users/change/info`.
struct ChangeUserInfoRequestDTO: Encodable {
    let name: String
    let email: String
    let phone: String?
    let companyName: String?
    let taxCode: String?

    enum CodingKeys: String, CodingKey {
        case name, email, phone
        case companyName = "company_name"
        case taxCode = "tax_code"
    }

    init(user: User) {
        name = user.name
        email = user.email
        phone = user.phone
        companyName = user.companyName
        taxCode = user.taxCode
    }
}
