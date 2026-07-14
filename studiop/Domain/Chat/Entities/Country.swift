import Foundation

/// Per `GET /location/list/country?token=`.
struct Country: Equatable, Identifiable {
    let id: String
    let name: String
    let code: String
    let dialCode: String?
}
