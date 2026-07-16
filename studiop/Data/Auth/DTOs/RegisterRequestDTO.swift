import Foundation

struct RegisterRequestDTO: Encodable {
    let name: String
    let firstName: String
    let email: String
    let password: String
    let passwordConfirmation: String
    let checkTerms: Bool

    enum CodingKeys: String, CodingKey {
        case name, email, password
        case firstName = "first_name"
        case passwordConfirmation = "password_confirmation"
        case checkTerms = "check_terms"
    }
}
