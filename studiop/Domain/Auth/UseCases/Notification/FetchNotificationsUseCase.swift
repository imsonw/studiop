import Foundation

struct FetchNotificationsUseCase {
    let repository: NotificationRepository

    init(repository: NotificationRepository) {
        self.repository = repository
    }

    func callAsFunction(cursor: String? = nil) async throws -> [NotificationItem] {
        try await repository.fetchNotifications(cursor: cursor)
    }
}
