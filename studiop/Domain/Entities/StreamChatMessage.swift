import Foundation

/// Chat message shape for `POST /studios/extension/stream/messages` — the chat fallback used for
/// web/social (non in-app) streams, and the shape returned by `POST /studios/stream/load/messages`.
struct StreamChatMessage: Identifiable, Equatable, Sendable {
    let messageId: String
    let account: String
    let fromUser: String
    let studioId: String
    let logId: String
    let comment: String
    let fullName: String
    let type: String
    let sourceType: LiveStreamSummary.SourceType

    var id: String { messageId }
}
