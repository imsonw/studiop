import Foundation
import Testing
@testable import studiop

private final class FakeGameRepository: GameRepository {
    var blackjackStatsResult: Result<BlackjackStats, Error> = .failure(FakeGameRepositoryError.unset)
    var recordBlackjackScoreResult: Result<Void, Error> = .success(())
    var listSpinWheelStudiosResult: Result<[SpinWheelStudioSummary], Error> = .failure(FakeGameRepositoryError.unset)
    var fetchSpinWheelConfigResult: Result<SpinWheelConfig, Error> = .failure(FakeGameRepositoryError.unset)
    var saveSpinWheelResultResult: Result<Void, Error> = .success(())

    private(set) var recordedScore: Int?
    private(set) var recordedCardsCount: Int?
    private(set) var requestedFilter: String?
    private(set) var requestedStudioIdEncode: String?
    private(set) var savedStudioID: String?
    private(set) var savedSpinwheelID: String?
    private(set) var savedResults: [SpinWheelResult]?

    func fetchBlackjackStats() async throws -> BlackjackStats {
        try blackjackStatsResult.get()
    }

    func recordBlackjackScore(score: Int, cardsCount: Int) async throws {
        recordedScore = score
        recordedCardsCount = cardsCount
        try recordBlackjackScoreResult.get()
    }

    func listSpinWheelStudios(filter: String) async throws -> [SpinWheelStudioSummary] {
        requestedFilter = filter
        return try listSpinWheelStudiosResult.get()
    }

    func fetchSpinWheelConfig(studioIdEncode: String) async throws -> SpinWheelConfig {
        requestedStudioIdEncode = studioIdEncode
        return try fetchSpinWheelConfigResult.get()
    }

    func saveSpinWheelResult(studioID: String, spinwheelID: String, results: [SpinWheelResult]) async throws {
        savedStudioID = studioID
        savedSpinwheelID = spinwheelID
        savedResults = results
        try saveSpinWheelResultResult.get()
    }
}

private enum FakeGameRepositoryError: Error, Equatable {
    case unset
    case boom
}

struct GameUseCaseTests {
    @Test func fetchBlackjackStatsForwardsRepositoryResult() async throws {
        let fake = FakeGameRepository()
        let stats = BlackjackStats(gamesPlayed: 12, bestScore: 21, bestCardsCount: 5)
        fake.blackjackStatsResult = .success(stats)
        let useCase = FetchBlackjackStatsUseCase(repository: fake)

        let result = try await useCase()

        #expect(result == stats)
    }

    @Test func fetchBlackjackStatsPropagatesRepositoryError() async {
        let fake = FakeGameRepository()
        fake.blackjackStatsResult = .failure(FakeGameRepositoryError.boom)
        let useCase = FetchBlackjackStatsUseCase(repository: fake)

        await #expect(throws: FakeGameRepositoryError.boom) {
            try await useCase()
        }
    }

    @Test func recordBlackjackScoreForwardsArguments() async throws {
        let fake = FakeGameRepository()
        let useCase = RecordBlackjackScoreUseCase(repository: fake)

        try await useCase(score: 19, cardsCount: 4)

        #expect(fake.recordedScore == 19)
        #expect(fake.recordedCardsCount == 4)
    }

    @Test func recordBlackjackScorePropagatesRepositoryError() async {
        let fake = FakeGameRepository()
        fake.recordBlackjackScoreResult = .failure(FakeGameRepositoryError.boom)
        let useCase = RecordBlackjackScoreUseCase(repository: fake)

        await #expect(throws: FakeGameRepositoryError.boom) {
            try await useCase(score: 19, cardsCount: 4)
        }
    }

    @Test func listSpinWheelStudiosForwardsFilterAndResult() async throws {
        let fake = FakeGameRepository()
        let summary = SpinWheelStudioSummary(
            id: "studio-1",
            spinwheelID: "wheel-1",
            studioName: "Test Studio",
            thumbnailURL: URL(string: "https://example.com/thumb.png")
        )
        fake.listSpinWheelStudiosResult = .success([summary])
        let useCase = ListSpinWheelStudiosUseCase(repository: fake)

        let result = try await useCase(filter: "active")

        #expect(fake.requestedFilter == "active")
        #expect(result == [summary])
    }

    @Test func fetchSpinWheelConfigForwardsStudioIdEncodeAndResult() async throws {
        let fake = FakeGameRepository()
        let config = SpinWheelConfig(
            studioID: "studio-1",
            spinwheelID: "wheel-1",
            segments: [SpinWheelSegment(id: "seg-1", prizeName: "10% off", imageURL: nil)],
            remainingSpins: 3
        )
        fake.fetchSpinWheelConfigResult = .success(config)
        let useCase = FetchSpinWheelConfigUseCase(repository: fake)

        let result = try await useCase(studioIdEncode: "encoded-studio-1")

        #expect(fake.requestedStudioIdEncode == "encoded-studio-1")
        #expect(result == config)
    }

    @Test func saveSpinWheelResultForwardsAllArguments() async throws {
        let fake = FakeGameRepository()
        let useCase = SaveSpinWheelResultUseCase(repository: fake)
        let results = [SpinWheelResult(segmentID: "seg-1", prizeName: "10% off", wonAt: Date(timeIntervalSince1970: 0))]

        try await useCase(studioID: "studio-1", spinwheelID: "wheel-1", results: results)

        #expect(fake.savedStudioID == "studio-1")
        #expect(fake.savedSpinwheelID == "wheel-1")
        #expect(fake.savedResults == results)
    }

    @Test func saveSpinWheelResultPropagatesRepositoryError() async {
        let fake = FakeGameRepository()
        fake.saveSpinWheelResultResult = .failure(FakeGameRepositoryError.boom)
        let useCase = SaveSpinWheelResultUseCase(repository: fake)

        await #expect(throws: FakeGameRepositoryError.boom) {
            try await useCase(studioID: "studio-1", spinwheelID: "wheel-1", results: [])
        }
    }
}
