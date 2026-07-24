import Dependencies
import Foundation
import UIKit

/// Downloads and caches images. `ImageCache` (below) is the version that ships; see
/// `GCDImageDownloader` for the DispatchSemaphore-gated comparison version
/// (docs/senior-skills-roadmap.md §1,7) — deliberately NOT behind this protocol, since it's a
/// standalone comparison piece, not something any shipping View calls.
protocol ImageLoading: Sendable {
    func image(for url: URL) async throws -> UIImage
    /// Warms the cache for many URLs at once (e.g. a product grid's visible thumbnails) so
    /// individual `image(for:)` calls resolve near-instantly afterward.
    func prefetch(_ urls: [URL]) async
}

/// Shared in-memory image cache + downloader, built with `actor` + `TaskGroup` — the senior-skill
/// comparison counterpart to `GCDImageDownloader`'s DispatchSemaphore-gated version. This is the
/// version that ships: concurrent downloads are coordinated by Swift Concurrency instead of a
/// manually-gated dispatch queue, and in-flight requests for the same URL are deduplicated by
/// storing the in-progress `Task` itself (not just the eventual result) so two views requesting
/// the same image at once share one download instead of racing two.
actor ImageCache: ImageLoading {
    enum LoadError: Error {
        case invalidData
    }

    private var cache: [URL: UIImage] = [:]
    private var inFlightTasks: [URL: Task<UIImage, Error>] = [:]

    func image(for url: URL) async throws -> UIImage {
        if let cached = cache[url] {
            return cached
        }
        if let existingTask = inFlightTasks[url] {
            return try await existingTask.value
        }

        let task = Task<UIImage, Error> {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else {
                throw LoadError.invalidData
            }
            return image
        }
        inFlightTasks[url] = task

        do {
            let image = try await task.value
            cache[url] = image
            inFlightTasks[url] = nil
            return image
        } catch {
            inFlightTasks[url] = nil
            throw error
        }
    }

    func prefetch(_ urls: [URL]) async {
        await withTaskGroup(of: Void.self) { group in
            for url in urls {
                group.addTask { _ = try? await self.image(for: url) }
            }
        }
    }
}

/// Deterministic fake for tests/previews — never touches the network. Returns a small solid-color
/// image synchronously (wrapped in `async`) so preview grids render something without a real URL.
private actor PreviewImageLoader: ImageLoading {
    func image(for url: URL) async throws -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { context in
            UIColor.systemGray4.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
    }

    func prefetch(_ urls: [URL]) async {}
}

private enum ImageLoadingKey: DependencyKey {
    static let liveValue: ImageLoading = ImageCache()
    static let testValue: ImageLoading = PreviewImageLoader()
    static let previewValue: ImageLoading = PreviewImageLoader()
}

extension DependencyValues {
    var imageLoading: ImageLoading {
        get { self[ImageLoadingKey.self] }
        set { self[ImageLoadingKey.self] = newValue }
    }
}
