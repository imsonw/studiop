import Foundation

/// A chat conversation list item, per `GET /chat/conversations`.
struct Conversation: Equatable, Identifiable {
    enum Context: String, Equatable {
        case account
        case studio
    }

    let id: String
    let context: Context
    let channel: String
    let lastMessagePreview: String?
    let lastMessageAt: Date?
    let unreadCount: Int
}
