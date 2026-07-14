import Foundation

/// Studio/seller profile — `POST /studios/interactions` and `GET /studios/list/interaction`.
struct StudioProfile: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let avatarURL: URL?
    let bannerURL: URL?
    let followerCount: Int
    let likeCount: Int
    let isFollowing: Bool
    let isLiked: Bool
}
