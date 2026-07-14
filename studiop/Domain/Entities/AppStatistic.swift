import Foundation

/// Shape per `GET /static/statistic`.
struct AppStatistic: Equatable, Identifiable {
    let id: String
    let label: String
    let value: String
}
