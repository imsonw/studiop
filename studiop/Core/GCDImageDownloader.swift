import Foundation
import UIKit

/// SENIOR-SKILL COMPARISON PIECE (docs/senior-skills-roadmap.md §1,7) — NOT wired into any
/// shipping screen. `ImageCache` (see `ImageLoading.swift`) is the version that actually ships;
/// this file exists solely so `dev_report` can compare the two side by side, answering the classic
/// "download N images concurrently" interview question the way it's usually asked: GCD +
/// `DispatchSemaphore` gating a fixed number of concurrent downloads, callback-based, no `async`.
///
/// Deliberately kept unreferenced by any View/ViewModel — do not wire this into the app.
final class GCDImageDownloader {
    private let semaphore: DispatchSemaphore
    private let queue: DispatchQueue

    /// `maxConcurrent` is the classic DispatchSemaphore parameter: the semaphore starts with this
    /// many permits, so at most this many downloads run at once regardless of how many URLs are
    /// requested — the same shape as an interview whiteboard answer.
    init(maxConcurrent: Int = 4) {
        semaphore = DispatchSemaphore(value: maxConcurrent)
        queue = DispatchQueue(label: "GCDImageDownloader", attributes: .concurrent)
    }

    /// Downloads every URL concurrently, gated to `maxConcurrent` in flight at a time, and calls
    /// `completion` once with everything that succeeded. `semaphore.wait()` blocks whichever
    /// background thread calls it once the permit count hits zero — by design, this must never
    /// run on the main thread, unlike the `async`/`await` version which never blocks a thread at
    /// all (it suspends instead).
    func downloadImages(urls: [URL], completion: @escaping ([URL: UIImage]) -> Void) {
        queue.async { [semaphore, queue] in
            var results: [URL: UIImage] = [:]
            let resultsLock = NSLock()
            let group = DispatchGroup()

            for url in urls {
                group.enter()
                semaphore.wait()
                queue.async {
                    defer {
                        semaphore.signal()
                        group.leave()
                    }
                    guard
                        let data = try? Data(contentsOf: url),
                        let image = UIImage(data: data)
                    else { return }
                    resultsLock.lock()
                    results[url] = image
                    resultsLock.unlock()
                }
            }

            group.wait()
            completion(results)
        }
    }
}
