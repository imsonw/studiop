import Foundation

/// A product brand — `GET /stores/brand/list`.
struct Brand: Equatable, Identifiable, Sendable {
    let id: String
    let name: String
    let logoURL: String?

    init(id: String, name: String, logoURL: String? = nil) {
        self.id = id
        self.name = name
        self.logoURL = logoURL
    }
}
