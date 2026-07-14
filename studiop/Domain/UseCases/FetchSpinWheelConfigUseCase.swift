import Foundation

struct FetchSpinWheelConfigUseCase {
    private let repository: GameRepository

    init(repository: GameRepository) {
        self.repository = repository
    }

    func callAsFunction(studioIdEncode: String) async throws -> SpinWheelConfig {
        try await repository.fetchSpinWheelConfig(studioIdEncode: studioIdEncode)
    }
}
