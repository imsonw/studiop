import Foundation

struct ConfirmResetPasswordRequestDTO: Encodable {
    let email: String
    let resetToken: String
    let newPassword: String
    let newPasswordConfirmation: String

    enum CodingKeys: String, CodingKey {
        case email
        case resetToken = "reset_token"
        case newPassword = "new_password"
        case newPasswordConfirmation = "new_password_confirmation"
    }
}
