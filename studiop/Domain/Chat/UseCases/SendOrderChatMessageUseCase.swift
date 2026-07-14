import Foundation

struct SendOrderChatMessageUseCase {
    let repository: ChatRepository

    func callAsFunction(
        orderID: String,
        body: String,
        bodyHTML: String? = nil,
        requestID: String? = nil
    ) async throws -> ChatMessage {
        try await repository.sendOrderMessage(orderID: orderID, body: body, bodyHTML: bodyHTML, requestID: requestID)
    }
}
