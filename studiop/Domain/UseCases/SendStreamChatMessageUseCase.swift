import Foundation

struct SendStreamChatMessageUseCase {
    let repository: StreamRepository

    func callAsFunction(_ message: StreamChatMessage) async throws {
        try await repository.sendStreamChatMessage(message)
    }
}
