import Foundation

/// An active lucky-wheel studio, as listed by `GET /games/spinwheel/list?f=`.
struct SpinWheelStudioSummary: Identifiable, Equatable {
    let id: String
    let spinwheelID: String
    let studioName: String
    let thumbnailURL: URL?
}
