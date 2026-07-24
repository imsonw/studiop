import Foundation

/// `GET /stores/categories?id=`.
///
/// - Note: UNCONFIRMED response field names — docs/api-reference.md documents only the request
///   shape for `StoreRepository`'s endpoints. Field names below follow this backend's established
///   snake_case convention (confirmed elsewhere via `UserDTO`/`AddressDTO`) as a best guess —
///   verify against real captured traffic or the Flutter source before treating as confirmed. Same
///   caveat applies to every DTO under `Data/Commerce`.
struct ProductCategoryDTO: Decodable {
    let idEncode: String
    let name: String
    let image: String?
    let parentId: String?
    let children: [ProductCategoryDTO]?

    enum CodingKeys: String, CodingKey {
        case idEncode = "id_encode"
        case name
        case image
        case parentId = "parent_id"
        case children
    }

    func toDomain() -> ProductCategory {
        ProductCategory(
            id: idEncode,
            name: name,
            imageURL: image,
            parentId: parentId,
            children: (children ?? []).map { $0.toDomain() }
        )
    }
}
