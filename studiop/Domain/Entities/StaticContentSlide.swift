import Foundation

/// A generic slide/banner item, per `GET /static/app_slides` and the generic slide-fetcher endpoint.
struct StaticContentSlide: Equatable, Identifiable {
    let id: String
    let imageURL: String
    let title: String?
    let linkURL: String?
}
