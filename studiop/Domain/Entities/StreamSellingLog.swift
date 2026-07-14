import Foundation

/// The "currently selling product" shape — `GET /studios/extension/stream/log?id=&sort=desc`,
/// polled every 5s for web/social streams. The Firebase RTDB equivalent (`studio_live_log`) used
/// for in-app streams is out of scope for this sprint.
struct StreamSellingLog: Identifiable, Equatable, Sendable {
    let id: String
    let streamId: String
    let productName: String
    let price: Double
    let quantity: Int
    let imageURL: URL?
    let imageThumbURL: URL?
    let createdAt: Date?
}
