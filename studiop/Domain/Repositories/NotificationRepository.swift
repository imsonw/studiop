import Foundation

/// Mirrors `/users/notifications` (cursor-paginated list) and `/users/notifications/{id}` (full
/// detail) in docs/api-reference.md.
protocol NotificationRepository: Sendable {
    func fetchNotificationDetail(id: Int) async throws -> NotificationItem

    /// `cursor` is `nil` for the first page; otherwise the opaque cursor from the previous page
    /// (the `time` query param on the backend).
    func fetchNotifications(cursor: String?) async throws -> [NotificationItem]
}
