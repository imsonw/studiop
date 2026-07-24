import Dependencies
import Foundation

private struct UnimplementedStudioRepository: StudioRepository {
    private struct Unimplemented: Error {}

    func toggleStudioInteraction(id: String, type: String) async throws {
        throw Unimplemented()
    }

    func listStudioInteractions(type: String, limit: Int, page: Int) async throws -> [StudioProfile] {
        throw Unimplemented()
    }

    func fetchStudioInteractionFilters() async throws -> [StudioInteractionFilter] {
        throw Unimplemented()
    }
}

private struct PreviewStudioRepository: StudioRepository {
    static let cannedProfiles: [StudioProfile] = [
        StudioProfile(
            id: "s1", name: "Preview Studio", avatarURL: nil, bannerURL: nil,
            followerCount: 120, likeCount: 45, isFollowing: true, isLiked: false
        ),
    ]
    static let cannedFilters: [StudioInteractionFilter] = [
        StudioInteractionFilter(type: "all", label: "All"),
        StudioInteractionFilter(type: "follow", label: "Following"),
        StudioInteractionFilter(type: "like", label: "Liked"),
        StudioInteractionFilter(type: "top_rated", label: "Top Rated"),
    ]

    func toggleStudioInteraction(id: String, type: String) async throws {}

    func listStudioInteractions(type: String, limit: Int, page: Int) async throws -> [StudioProfile] {
        Self.cannedProfiles
    }

    func fetchStudioInteractionFilters() async throws -> [StudioInteractionFilter] {
        Self.cannedFilters
    }
}

private enum StudioRepositoryKey: DependencyKey {
    static var liveValue: StudioRepository {
        @Dependency(\.networkClient) var networkClient
        return StudioRepositoryImpl(networkClient: networkClient)
    }

    static let testValue: StudioRepository = UnimplementedStudioRepository()
    static let previewValue: StudioRepository = PreviewStudioRepository()
}

extension DependencyValues {
    var studioRepository: StudioRepository {
        get { self[StudioRepositoryKey.self] }
        set { self[StudioRepositoryKey.self] = newValue }
    }
}
