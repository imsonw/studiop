import Foundation
import Testing
@testable import studiop

private final class FakeLocationRepository: LocationRepository {
    var result: Result<[Country], Error> = .success([])

    func fetchCountryList() async throws -> [Country] {
        try result.get()
    }
}

private enum TestError: Error, Equatable { case boom }

struct LocationUseCaseTests {
    @Test func fetchCountryListForwardsResult() async throws {
        let fake = FakeLocationRepository()
        let expected = [Country(id: "1", name: "Netherlands", code: "NL", dialCode: "+31")]
        fake.result = .success(expected)
        let useCase = FetchCountryListUseCase(repository: fake)

        let result = try await useCase()

        #expect(result == expected)
    }

    @Test func fetchCountryListPropagatesError() async throws {
        let fake = FakeLocationRepository()
        fake.result = .failure(TestError.boom)
        let useCase = FetchCountryListUseCase(repository: fake)

        do {
            _ = try await useCase()
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error as? TestError == .boom)
        }
    }
}
