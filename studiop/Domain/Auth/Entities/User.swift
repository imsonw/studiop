import Foundation

/// The user profile shape returned by `GET /users/info` and used across the Auth/User endpoints
/// (`/users/change/profile`, `/users/change/info`). A Domain entity, not a DTO — it does not mirror
/// backend JSON keys exactly.
struct User: Equatable, Sendable, Identifiable {
    let id: Int
    let idEncode: String
    var name: String
    var email: String
    var phone: String?
    var avatarURL: String?
    var companyName: String?
    var taxCode: String?
    var socialProvider: String?

    init(
        id: Int,
        idEncode: String,
        name: String,
        email: String,
        phone: String? = nil,
        avatarURL: String? = nil,
        companyName: String? = nil,
        taxCode: String? = nil,
        socialProvider: String? = nil
    ) {
        self.id = id
        self.idEncode = idEncode
        self.name = name
        self.email = email
        self.phone = phone
        self.avatarURL = avatarURL
        self.companyName = companyName
        self.taxCode = taxCode
        self.socialProvider = socialProvider
    }
}
