import Foundation

/// REST-only chat operations. Ably realtime channel subscription is modeled in a later sprint.
protocol ChatRepository {
    func issueAblyToken() async throws -> AblyTokenGrant

    func fetchConversations(
        context: Conversation.Context,
        channel: String?,
        page: Int?,
        perPage: Int?
    ) async throws -> [Conversation]

    func fetchOrderMessages(
        orderID: String,
        limit: Int?,
        beforeTimestamp: Date?,
        beforeID: String?,
        preview: Bool?
    ) async throws -> [ChatMessage]

    func sendOrderMessage(
        orderID: String,
        body: String,
        bodyHTML: String?,
        requestID: String?
    ) async throws -> ChatMessage

    func fetchSupportMessages(
        limit: Int?,
        beforeTimestamp: Date?,
        preview: Bool?
    ) async throws -> [ChatMessage]

    func sendSupportMessage(
        body: String,
        bodyHTML: String?,
        requestID: String?
    ) async throws -> ChatMessage

    func setConversationActive(conversationID: String, ttlSeconds: Int) async throws

    func clearConversationActive(conversationID: String) async throws

    func markConversationRead(conversationID: String) async throws

    func syncUnread() async throws
}
