import Foundation

struct SendSupportChatMessageUseCase {
    let repository: ChatRepository

    func callAsFunction(
        body: String,
        bodyHTML: String? = nil,
        requestID: String? = nil
    ) async throws -> ChatMessage {
        try await repository.sendSupportMessage(body: body, bodyHTML: bodyHTML, requestID: requestID)
    }
}
