import Foundation

/// `GET /stores/brand/list`. See `ProductCategoryDTO`'s note on unconfirmed field names.
struct BrandDTO: Decodable {
    let idEncode: String
    let name: String
    let logo: String?

    enum CodingKeys: String, CodingKey {
        case idEncode = "id_encode"
        case name
        case logo
    }

    func toDomain() -> Brand {
        Brand(id: idEncode, name: name, logoURL: logo)
    }
}
