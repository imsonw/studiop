import Foundation

struct SetConversationActiveUseCase {
    let repository: ChatRepository

    func callAsFunction(conversationID: String, ttlSeconds: Int) async throws {
        try await repository.setConversationActive(conversationID: conversationID, ttlSeconds: ttlSeconds)
    }
}
