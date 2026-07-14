import Foundation

/// Filter label shape — `GET /studios/list/interaction/filters` (e.g. all / like / follow / top_rated).
struct StudioInteractionFilter: Identifiable, Equatable, Sendable {
    let type: String
    let label: String

    var id: String { type }
}
