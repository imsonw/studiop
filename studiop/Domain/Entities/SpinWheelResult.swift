import Foundation

/// A single spin outcome — submitted as part of `results[]` in the save-result call, and also
/// used to represent the outcome of a spin back to the caller.
struct SpinWheelResult: Equatable {
    let segmentID: String
    let prizeName: String
    let wonAt: Date
}
