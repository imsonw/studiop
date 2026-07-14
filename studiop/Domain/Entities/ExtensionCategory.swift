import Foundation

/// Per `GET /studios/extension/list/categories`.
struct ExtensionCategory: Equatable, Identifiable {
    let id: String
    let name: String
    let iconURL: String?
}
