import Foundation

/// A product category — `GET /stores/categories?id=`.
struct ProductCategory: Equatable, Identifiable, Sendable {
    let id: String
    let name: String
    let imageURL: String?
    let parentId: String?
    let children: [ProductCategory]

    init(
        id: String,
        name: String,
        imageURL: String? = nil,
        parentId: String? = nil,
        children: [ProductCategory] = []
    ) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.parentId = parentId
        self.children = children
    }
}
