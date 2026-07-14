import Foundation

struct FetchOrderChatMessagesUseCase {
    let repository: ChatRepository

    func callAsFunction(
        orderID: String,
        limit: Int? = nil,
        beforeTimestamp: Date? = nil,
        beforeID: String? = nil,
        preview: Bool? = nil
    ) async throws -> [ChatMessage] {
        try await repository.fetchOrderMessages(
            orderID: orderID,
            limit: limit,
            beforeTimestamp: beforeTimestamp,
            beforeID: beforeID,
            preview: preview
        )
    }
}
