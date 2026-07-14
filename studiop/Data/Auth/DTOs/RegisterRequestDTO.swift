import Foundation

struct RegisterRequestDTO: Encodable {
    let name: String
    let email: String
    let password: String
    let passwordConfirmation: String
    let phone: String?

    enum CodingKeys: String, CodingKey {
        case name, email, password, phone
        case passwordConfirmation = "password_confirmation"
    }
}
