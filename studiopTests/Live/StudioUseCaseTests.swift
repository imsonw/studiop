import Foundation
import Testing
@testable import studiop

private enum FakeError: Error, Equatable {
    case boom
}

private final class FakeStudioRepository: StudioRepository, @unchecked Sendable {
    var toggleInteractionError: Error?
    var listInteractionsResult: Result<[StudioProfile], Error> = .success([])
    var filtersResult: Result<[StudioInteractionFilter], Error> = .success([])

    private(set) var receivedToggleId: String?
    private(set) var receivedToggleType: String?
    private(set) var receivedListArgs: (type: String, limit: Int, page: Int)?

    func toggleStudioInteraction(id: String, type: String) async throws {
        receivedToggleId = id
        receivedToggleType = type
        if let toggleInteractionError { throw toggleInteractionError }
    }

    func listStudioInteractions(type: String, limit: Int, page: Int) async throws -> [StudioProfile] {
        receivedListArgs = (type, limit, page)
        return try listInteractionsResult.get()
    }

    func fetchStudioInteractionFilters() async throws -> [StudioInteractionFilter] {
        try filtersResult.get()
    }
}

private func makeProfile(id: String = "studio1") -> StudioProfile {
    StudioProfile(
        id: id,
        name: "Studio One",
        avatarURL: nil,
        bannerURL: nil,
        followerCount: 10,
        likeCount: 5,
        isFollowing: true,
        isLiked: false
    )
}

struct StudioUseCaseTests {
    @Test func toggleStudioInteractionForwardsArgs() async throws {
        let repository = FakeStudioRepository()
        let useCase = ToggleStudioInteractionUseCase(repository: repository)

        try await useCase(id: "studio1", type: "like")

        #expect(repository.receivedToggleId == "studio1")
        #expect(repository.receivedToggleType == "like")
    }

    @Test func toggleStudioInteractionPropagatesError() async throws {
        let repository = FakeStudioRepository()
        repository.toggleInteractionError = FakeError.boom
        let useCase = ToggleStudioInteractionUseCase(repository: repository)

        await #expect(throws: FakeError.self) {
            try await useCase(id: "studio1", type: "follow")
        }
    }

    @Test func listStudioInteractionsForwardsArgsAndResult() async throws {
        let repository = FakeStudioRepository()
        let expected = [makeProfile()]
        repository.listInteractionsResult = .success(expected)
        let useCase = ListStudioInteractionsUseCase(repository: repository)

        let result = try await useCase(type: "follow", limit: 20, page: 1)

        #expect(result == expected)
        let args = try #require(repository.receivedListArgs)
        #expect(args.type == "follow")
        #expect(args.limit == 20)
        #expect(args.page == 1)
    }

    @Test func listStudioInteractionsPropagatesError() async throws {
        let repository = FakeStudioRepository()
        repository.listInteractionsResult = .failure(FakeError.boom)
        let useCase = ListStudioInteractionsUseCase(repository: repository)

        await #expect(throws: FakeError.self) {
            try await useCase(type: "all", limit: 10, page: 1)
        }
    }

    @Test func fetchStudioInteractionFiltersForwardsResult() async throws {
        let repository = FakeStudioRepository()
        let filters = [StudioInteractionFilter(type: "all", label: "All")]
        repository.filtersResult = .success(filters)
        let useCase = FetchStudioInteractionFiltersUseCase(repository: repository)

        let result = try await useCase()

        #expect(result == filters)
    }
}
