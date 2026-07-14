import Foundation

struct ListStudioInteractionsUseCase {
    let repository: StudioRepository

    func callAsFunction(type: String, limit: Int, page: Int) async throws -> [StudioProfile] {
        try await repository.listStudioInteractions(type: type, limit: limit, page: page)
    }
}
