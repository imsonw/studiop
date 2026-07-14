import Foundation

struct FetchCountryListUseCase {
    let repository: LocationRepository

    func callAsFunction() async throws -> [Country] {
        try await repository.fetchCountryList()
    }
}
