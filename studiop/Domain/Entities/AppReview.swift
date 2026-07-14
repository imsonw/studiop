import Foundation

/// A homepage/app-level review quote, per `GET /static/app_reviews`.
struct AppReview: Equatable, Identifiable {
    let id: String
    let authorName: String
    let avatarURL: String?
    let rating: Double
    let comment: String
}
