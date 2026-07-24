import Dependencies
import SwiftUI

/// Loads an image through the shared `ImageLoading` cache (`Core/ImageLoading.swift`'s
/// `TaskGroup`/actor-based version) instead of SwiftUI's built-in `AsyncImage`, which downloads
/// independently per instance with no cross-view cache. Used by the Storefront grid (F-017) and
/// Product detail carousel (F-018) — the two image-heaviest screens this sprint.
struct CachedAsyncImageView: View {
    let urlString: String?

    @State private var image: UIImage?
    @State private var failed = false

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
            } else if failed || urlString == nil {
                Color.gray.opacity(0.15)
            } else {
                Color.gray.opacity(0.15)
                    .overlay(ProgressView())
            }
        }
        .task(id: urlString) {
            guard let urlString, let url = URL(string: urlString) else {
                failed = true
                return
            }
            @Dependency(\.imageLoading) var imageLoading
            do {
                image = try await imageLoading.image(for: url)
            } catch {
                failed = true
            }
        }
    }
}
