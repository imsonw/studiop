import Foundation

/// A notification list/detail item per `/users/notifications` (cursor-paginated list) and
/// `/users/notifications/{id}` (full detail).
struct NotificationItem: Equatable, Sendable, Identifiable {
    let id: Int
    var title: String
    var body: String
    var isRead: Bool
    var createdAt: Date

    init(id: Int, title: String, body: String, isRead: Bool, createdAt: Date) {
        self.id = id
        self.title = title
        self.body = body
        self.isRead = isRead
        self.createdAt = createdAt
    }
}
