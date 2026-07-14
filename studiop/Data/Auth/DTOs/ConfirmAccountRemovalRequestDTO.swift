import Foundation

struct ConfirmAccountRemovalRequestDTO: Encodable {
    let email: String
    let code: String
}
