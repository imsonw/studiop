import Foundation

/// A player's cumulative Blackjack performance, per `GET /mobile/blackjack/stats`.
struct BlackjackStats: Equatable {
    let gamesPlayed: Int
    let bestScore: Int
    let bestCardsCount: Int
}
