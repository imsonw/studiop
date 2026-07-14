import Foundation

struct ListSpinWheelStudiosUseCase {
    private let repository: GameRepository

    init(repository: GameRepository) {
        self.repository = repository
    }

    func callAsFunction(filter: String) async throws -> [SpinWheelStudioSummary] {
        try await repository.listSpinWheelStudios(filter: filter)
    }
}
