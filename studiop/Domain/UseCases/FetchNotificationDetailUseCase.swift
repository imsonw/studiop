import Foundation

struct FetchNotificationDetailUseCase {
    let repository: NotificationRepository

    init(repository: NotificationRepository) {
        self.repository = repository
    }

    func callAsFunction(id: Int) async throws -> NotificationItem {
        try await repository.fetchNotificationDetail(id: id)
    }
}
