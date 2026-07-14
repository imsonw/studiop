import Foundation

struct SyncUnreadUseCase {
    let repository: ChatRepository

    func callAsFunction() async throws {
        try await repository.syncUnread()
    }
}
