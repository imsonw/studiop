import Foundation

struct FetchAppStatisticUseCase {
    let repository: StaticContentRepository

    func callAsFunction() async throws -> [AppStatistic] {
        try await repository.fetchAppStatistic()
    }
}
