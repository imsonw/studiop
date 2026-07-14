import Foundation

/// Studio/seller profile REST surface — see docs/api-reference.md -> `StudioRepository`.
protocol StudioRepository: Sendable {
    /// `POST /studios/interactions?id=&type=` — like/unlike or follow/unfollow.
    func toggleStudioInteraction(id: String, type: String) async throws

    /// `GET /studios/list/interaction?type=&limit=&page=` — all / like / follow / top_rated.
    func listStudioInteractions(type: String, limit: Int, page: Int) async throws -> [StudioProfile]

    /// `GET /studios/list/interaction/filters`
    func fetchStudioInteractionFilters() async throws -> [StudioInteractionFilter]
}
