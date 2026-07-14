import Foundation
import Testing
@testable import studiop

private struct StubError: Error, Equatable {}

final class FakeNotificationRepository: NotificationRepository, @unchecked Sendable {
    var detailToReturn = NotificationItem(id: 1, title: "Order shipped", body: "Your order is on its way", isRead: false, createdAt: Date(timeIntervalSince1970: 0))
    var listToReturn: [NotificationItem] = []
    var errorToThrow: Error?

    private(set) var lastDetailID: Int?
    private(set) var lastCursor: String??

    func fetchNotificationDetail(id: Int) async throws -> NotificationItem {
        lastDetailID = id
        if let errorToThrow { throw errorToThrow }
        return detailToReturn
    }

    func fetchNotifications(cursor: String?) async throws -> [NotificationItem] {
        lastCursor = cursor
        if let errorToThrow { throw errorToThrow }
        return listToReturn
    }
}

struct NotificationUseCaseTests {
    @Test func fetchNotificationDetailForwardsIDAndReturnsItem() async throws {
        let fake = FakeNotificationRepository()
        let useCase = FetchNotificationDetailUseCase(repository: fake)

        let result = try await useCase(id: 42)

        #expect(fake.lastDetailID == 42)
        #expect(result == fake.detailToReturn)
    }

    @Test func fetchNotificationDetailPropagatesError() async throws {
        let fake = FakeNotificationRepository()
        fake.errorToThrow = StubError()
        let useCase = FetchNotificationDetailUseCase(repository: fake)

        await #expect(throws: StubError.self) {
            _ = try await useCase(id: 42)
        }
    }

    @Test func fetchNotificationsForwardsNilCursorOnFirstPage() async throws {
        let fake = FakeNotificationRepository()
        fake.listToReturn = [fake.detailToReturn]
        let useCase = FetchNotificationsUseCase(repository: fake)

        let result = try await useCase()

        #expect(fake.lastCursor == .some(nil))
        #expect(result == fake.listToReturn)
    }

    @Test func fetchNotificationsForwardsGivenCursor() async throws {
        let fake = FakeNotificationRepository()
        let useCase = FetchNotificationsUseCase(repository: fake)

        _ = try await useCase(cursor: "2026-07-14T00:00:00Z")

        #expect(fake.lastCursor == .some("2026-07-14T00:00:00Z"))
    }
}
