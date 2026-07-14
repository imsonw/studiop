import Foundation

/// A single prize segment on the wheel.
struct SpinWheelSegment: Identifiable, Equatable {
    let id: String
    let prizeName: String
    let imageURL: URL?
}

/// The wheel configuration for a studio, per `GET /games/spinwheel/get/{studioIdEncode}`.
struct SpinWheelConfig: Equatable {
    let studioID: String
    let spinwheelID: String
    let segments: [SpinWheelSegment]
    let remainingSpins: Int
}
