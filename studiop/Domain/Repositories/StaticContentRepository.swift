import Foundation

protocol StaticContentRepository {
    func fetchAppSlides() async throws -> [StaticContentSlide]

    func fetchAppStatistic() async throws -> [AppStatistic]

    func fetchAppReviews() async throws -> [AppReview]

    func fetchExtensionCategories() async throws -> [ExtensionCategory]

    /// Generic slide-fetcher — hits whatever path is passed.
    func fetchSlides(path: String) async throws -> [StaticContentSlide]
}
