import Foundation

/// A single chat message, per `/chat/orders/{orderId}/messages` and `/chat/support/messages`.
struct ChatMessage: Equatable, Identifiable {
    let id: String
    let body: String
    let bodyHTML: String?
    let senderID: String
    let senderName: String?
    let sentAt: Date
    /// Client-generated id used to reconcile an optimistically-sent message with the server echo.
    let requestID: String?
}
