import Foundation

struct FetchStudioInteractionFiltersUseCase {
    let repository: StudioRepository

    func callAsFunction() async throws -> [StudioInteractionFilter] {
        try await repository.fetchStudioInteractionFilters()
    }
}
