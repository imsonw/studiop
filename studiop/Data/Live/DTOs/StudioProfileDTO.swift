import Foundation

/// `GET /studios/list/interaction`.
///
/// - Note: UNCONFIRMED response field names — docs/api-reference.md documents only the request
///   shape. Field names below follow this backend's established snake_case convention as a best
///   guess — verify against real captured traffic or the Flutter source before treating as
///   confirmed, same discipline as `Data/Commerce`'s DTOs.
struct StudioProfileDTO: Decodable {
    let idEncode: String
    let name: String
    let avatar: String?
    let banner: String?
    let followerCount: Int?
    let likeCount: Int?
    let isFollowing: Bool?
    let isLiked: Bool?

    enum CodingKeys: String, CodingKey {
        case idEncode = "id_encode"
        case name
        case avatar
        case banner
        case followerCount = "follower_count"
        case likeCount = "like_count"
        case isFollowing = "is_following"
        case isLiked = "is_liked"
    }

    func toDomain() -> StudioProfile {
        StudioProfile(
            id: idEncode,
            name: name,
            avatarURL: avatar.flatMap(URL.init(string:)),
            bannerURL: banner.flatMap(URL.init(string:)),
            followerCount: followerCount ?? 0,
            likeCount: likeCount ?? 0,
            isFollowing: isFollowing ?? false,
            isLiked: isLiked ?? false
        )
    }
}
