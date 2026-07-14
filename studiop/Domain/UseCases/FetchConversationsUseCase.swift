import Foundation

struct FetchConversationsUseCase {
    let repository: ChatRepository

    func callAsFunction(
        context: Conversation.Context,
        channel: String? = nil,
        page: Int? = nil,
        perPage: Int? = nil
    ) async throws -> [Conversation] {
        try await repository.fetchConversations(context: context, channel: channel, page: page, perPage: perPage)
    }
}
