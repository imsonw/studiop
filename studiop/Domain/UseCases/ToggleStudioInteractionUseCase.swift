import Foundation

struct ToggleStudioInteractionUseCase {
    let repository: StudioRepository

    func callAsFunction(id: String, type: String) async throws {
        try await repository.toggleStudioInteraction(id: id, type: type)
    }
}
