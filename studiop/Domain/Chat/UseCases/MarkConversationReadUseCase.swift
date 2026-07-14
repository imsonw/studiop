import Foundation

struct MarkConversationReadUseCase {
    let repository: ChatRepository

    func callAsFunction(conversationID: String) async throws {
        try await repository.markConversationRead(conversationID: conversationID)
    }
}
