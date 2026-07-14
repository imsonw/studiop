import Foundation

struct IssueAblyTokenUseCase {
    let repository: ChatRepository

    func callAsFunction() async throws -> AblyTokenGrant {
        try await repository.issueAblyToken()
    }
}
