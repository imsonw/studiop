import Foundation

struct RecordBlackjackScoreUseCase {
    private let repository: GameRepository

    init(repository: GameRepository) {
        self.repository = repository
    }

    func callAsFunction(score: Int, cardsCount: Int) async throws {
        try await repository.recordBlackjackScore(score: score, cardsCount: cardsCount)
    }
}
