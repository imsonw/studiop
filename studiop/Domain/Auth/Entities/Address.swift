import Foundation

/// A shipping/billing address per `/users/address/*`. `id` is `nil` for an address not yet
/// persisted by the backend (e.g. the value passed into a create call).
struct Address: Equatable, Sendable, Identifiable {
    var id: Int?
    var fullName: String
    var phone: String
    var address: String
    var houseNumber: String
    var postalCode: String
    var location: String
    var country: String
    var isDefault: Bool

    init(
        id: Int? = nil,
        fullName: String,
        phone: String,
        address: String,
        houseNumber: String,
        postalCode: String,
        location: String,
        country: String,
        isDefault: Bool = false
    ) {
        self.id = id
        self.fullName = fullName
        self.phone = phone
        self.address = address
        self.houseNumber = houseNumber
        self.postalCode = postalCode
        self.location = location
        self.country = country
        self.isDefault = isDefault
    }
}
