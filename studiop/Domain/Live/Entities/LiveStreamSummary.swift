import Foundation

/// Live stream list item — `GET /studios/extension/list/live?type=&id_encode=`.
/// Also doubles as the shape returned by `GET /studios/stream/last_stream` (poll for the caller's
/// own in-progress stream).
struct LiveStreamSummary: Identifiable, Equatable, Sendable {
    /// Which player renders this stream — one per source per docs/architecture.md roadmap.
    enum SourceType: String, Equatable, Sendable {
        case native
        case tiktok
        case twitch
        case youtube
        case castr
    }

    let id: String
    let title: String
    let thumbnailURL: URL?
    let studioId: String
    let studioName: String
    let sourceType: SourceType
    let isLive: Bool
}
