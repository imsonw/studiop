import Foundation

/// `GET /studios/list/interaction/filters`. See `StudioProfileDTO`'s note on unconfirmed field
/// names.
struct StudioInteractionFilterDTO: Decodable {
    let type: String
    let label: String

    func toDomain() -> StudioInteractionFilter {
        StudioInteractionFilter(type: type, label: label)
    }
}
