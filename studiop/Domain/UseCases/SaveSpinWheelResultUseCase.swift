import Foundation

struct SaveSpinWheelResultUseCase {
    private let repository: GameRepository

    init(repository: GameRepository) {
        self.repository = repository
    }

    func callAsFunction(studioID: String, spinwheelID: String, results: [SpinWheelResult]) async throws {
        try await repository.saveSpinWheelResult(studioID: studioID, spinwheelID: spinwheelID, results: results)
    }
}
