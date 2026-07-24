import Foundation

/// All `StudioRepository` calls use `.userToken` (`NetworkRequest`'s default) — following/liking a
/// studio is account-scoped.
final class StudioRepositoryImpl: StudioRepository {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    func toggleStudioInteraction(id: String, type: String) async throws {
        _ = try await networkClient.send(
            NetworkRequest(
                path: "studios/interactions",
                method: .post,
                queryItems: [URLQueryItem(name: "id", value: id), URLQueryItem(name: "type", value: type)]
            )
        )
    }

    func listStudioInteractions(type: String, limit: Int, page: Int) async throws -> [StudioProfile] {
        let data = try await networkClient.send(
            NetworkRequest(
                path: "studios/list/interaction",
                queryItems: [
                    URLQueryItem(name: "type", value: type),
                    URLQueryItem(name: "limit", value: String(limit)),
                    URLQueryItem(name: "page", value: String(page)),
                ]
            )
        )
        return try JSONDecoder().decode(DataResponseDTO<[StudioProfileDTO]>.self, from: data).data.map { $0.toDomain() }
    }

    func fetchStudioInteractionFilters() async throws -> [StudioInteractionFilter] {
        let data = try await networkClient.send(NetworkRequest(path: "studios/list/interaction/filters"))
        return try JSONDecoder().decode(DataResponseDTO<[StudioInteractionFilterDTO]>.self, from: data).data
            .map { $0.toDomain() }
    }
}
