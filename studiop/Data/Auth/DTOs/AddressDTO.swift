import Foundation

struct AddressDTO: Codable {
    let id: Int?
    let fullName: String
    let phone: String
    let address: String
    let houseNumber: String
    let postalCode: String
    let location: String
    let country: String
    let isDefault: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case phone
        case address
        case houseNumber = "house_number"
        case postalCode = "postal_code"
        case location
        case country
        case isDefault = "is_default"
    }

    init(domain: Address) {
        id = domain.id
        fullName = domain.fullName
        phone = domain.phone
        address = domain.address
        houseNumber = domain.houseNumber
        postalCode = domain.postalCode
        location = domain.location
        country = domain.country
        isDefault = domain.isDefault
    }

    func toDomain() -> Address {
        Address(
            id: id,
            fullName: fullName,
            phone: phone,
            address: address,
            houseNumber: houseNumber,
            postalCode: postalCode,
            location: location,
            country: country,
            isDefault: isDefault
        )
    }
}
