import Foundation

/// Live streaming REST surface — see docs/api-reference.md -> `StreamRepository (live streaming)`.
/// Firebase RTDB paths (viewer counts, in-app chat, "now selling" for in-app streams) are modeled
/// separately in a later sprint, alongside the live-viewing feature.
protocol StreamRepository: Sendable {
    /// `GET /studios/extension/list/live?type=&id_encode=`
    func fetchLiveStreamList(type: String?, idEncode: String?) async throws -> [LiveStreamSummary]

    /// `POST /studios/extension/stream/messages` — chat fallback for web/social streams.
    func sendStreamChatMessage(_ message: StreamChatMessage) async throws

    /// `GET /studios/extension/stream/log?id=&sort=desc` — poll every 5s, only when the stream is
    /// NOT in-app.
    func fetchStreamSellingLog(id: String, sort: String) async throws -> StreamSellingLog?

    /// `POST /studios/stream/start`
    func startStream(
        productName: String,
        price: Double,
        quantity: Int,
        image: String,
        imageThumb: String
    ) async throws

    /// `POST /studios/stream/end`
    func endStream(id: String) async throws

    /// `GET /studios/stream/last_stream` — poll for the caller's own in-progress stream.
    func fetchLastStream() async throws -> LiveStreamSummary?

    /// `POST /studios/stream/load/messages`
    func loadStreamMessages(id: String) async throws -> [StreamChatMessage]

    /// `GET /schedules/noti?id=` — scheduled livestream detail, opened from a push notification.
    func fetchScheduledStream(id: String) async throws -> ScheduledStream
}
