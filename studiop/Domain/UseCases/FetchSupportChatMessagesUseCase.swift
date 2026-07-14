import Foundation

struct FetchSupportChatMessagesUseCase {
    let repository: ChatRepository

    func callAsFunction(
        limit: Int? = nil,
        beforeTimestamp: Date? = nil,
        preview: Bool? = nil
    ) async throws -> [ChatMessage] {
        try await repository.fetchSupportMessages(limit: limit, beforeTimestamp: beforeTimestamp, preview: preview)
    }
}
