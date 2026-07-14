import Foundation

/// Partial-profile update body for `/users/change/profile`.
struct ChangeUserProfileRequestDTO: Encodable {
    let name: String?
    let phone: String?
    let email: String?
    let companyName: String?
    let taxCode: String?
    let socialProvider: String?

    enum CodingKeys: String, CodingKey {
        case name, phone, email
        case companyName = "company_name"
        case taxCode = "tax_code"
        case socialProvider = "social_provider"
    }
}
