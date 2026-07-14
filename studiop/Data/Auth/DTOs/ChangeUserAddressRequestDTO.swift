import Foundation

/// Body for `/users/change/address` ("main + shipping address").
/// - Note: docs/api-reference.md doesn't give the literal wrapper field names — `main_address`/
///   `shipping_address` is a best guess pending backend confirmation.
struct ChangeUserAddressRequestDTO: Encodable {
    let mainAddress: AddressDTO
    let shippingAddress: AddressDTO?

    enum CodingKeys: String, CodingKey {
        case mainAddress = "main_address"
        case shippingAddress = "shipping_address"
    }
}
