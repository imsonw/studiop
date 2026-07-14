import Foundation

/// Scheduled livestream detail — `GET /schedules/noti?id=`, opened from a push notification.
struct ScheduledStream: Identifiable, Equatable, Sendable {
    let id: String
    let studioId: String
    let studioName: String
    let title: String
    let scheduledAt: Date
    let thumbnailURL: URL?
    let sourceType: LiveStreamSummary.SourceType?
}
