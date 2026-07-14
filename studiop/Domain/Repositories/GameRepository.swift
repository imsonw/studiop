import Foundation

/// Blackjack + Lucky Wheel mini-games, per docs/api-reference.md → `GameRepository`.
protocol GameRepository {
    /// `GET /mobile/blackjack/stats`
    func fetchBlackjackStats() async throws -> BlackjackStats

    /// `POST /mobile/blackjack/record` — body `{score, cards_count}`.
    func recordBlackjackScore(score: Int, cardsCount: Int) async throws

    /// `GET /games/spinwheel/list?f=` — active lucky-wheel studios.
    func listSpinWheelStudios(filter: String) async throws -> [SpinWheelStudioSummary]

    /// `GET /games/spinwheel/get/{studioIdEncode}` — wheel config.
    func fetchSpinWheelConfig(studioIdEncode: String) async throws -> SpinWheelConfig

    /// `POST /games/spinwheel/save_result` — body `{studio_id, spinwheel_id, results[]}`.
    func saveSpinWheelResult(studioID: String, spinwheelID: String, results: [SpinWheelResult]) async throws
}
