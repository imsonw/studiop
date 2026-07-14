import Foundation

struct ClearConversationActiveUseCase {
    let repository: ChatRepository

    func callAsFunction(conversationID: String) async throws {
        try await repository.clearConversationActive(conversationID: conversationID)
    }
}
