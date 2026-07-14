import Foundation

struct VerifyAccountRequestDTO: Encodable {
    let email: String
    let code: String
}
