import Foundation

struct LoadStreamMessagesUseCase {
    let repository: StreamRepository

    func callAsFunction(id: String) async throws -> [StreamChatMessage] {
        try await repository.loadStreamMessages(id: id)
    }
}
