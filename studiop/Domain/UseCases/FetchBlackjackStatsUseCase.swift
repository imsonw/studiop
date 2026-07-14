import Foundation

struct FetchBlackjackStatsUseCase {
    private let repository: GameRepository

    init(repository: GameRepository) {
        self.repository = repository
    }

    func callAsFunction() async throws -> BlackjackStats {
        try await repository.fetchBlackjackStats()
    }
}
