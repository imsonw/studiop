import Foundation

@MainActor
@Observable
final class SearchViewModel {
    private static let recentSearchesKey = "commerce.recentSearches"
    private static let maxRecentSearches = 10

    var query: String = "" {
        didSet { scheduleAutocomplete() }
    }
    private(set) var results: [ProductSummary] = []
    private(set) var suggestedProducts: [ProductSummary] = []
    private(set) var recentSearches: [String] = []
    var isLoading = false
    var errorMessage: String?

    private let fetchProductListUseCase: FetchProductListUseCase
    private let fetchPopularProductsUseCase: FetchPopularProductsUseCase
    private let userDefaults: UserDefaults
    private var autocompleteTask: Task<Void, Never>?

    init(
        fetchProductListUseCase: FetchProductListUseCase,
        fetchPopularProductsUseCase: FetchPopularProductsUseCase,
        userDefaults: UserDefaults = .standard
    ) {
        self.fetchProductListUseCase = fetchProductListUseCase
        self.fetchPopularProductsUseCase = fetchPopularProductsUseCase
        self.userDefaults = userDefaults
        recentSearches = userDefaults.stringArray(forKey: Self.recentSearchesKey) ?? []
    }

    func loadSuggestions() async {
        do {
            suggestedProducts = try await fetchPopularProductsUseCase(limit: 10)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Debounces autocomplete-as-you-type so every keystroke doesn't fire its own network call.
    private func scheduleAutocomplete() {
        autocompleteTask?.cancel()
        let currentQuery = query
        guard !currentQuery.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = []
            return
        }
        autocompleteTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            await runSearch(currentQuery)
        }
    }

    func submitSearch() async {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        saveRecentSearch(trimmed)
        await runSearch(trimmed)
    }

    private func runSearch(_ text: String) async {
        isLoading = true
        errorMessage = nil
        do {
            results = try await fetchProductListUseCase(query: text)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func saveRecentSearch(_ text: String) {
        var updated = recentSearches.filter { $0 != text }
        updated.insert(text, at: 0)
        recentSearches = Array(updated.prefix(Self.maxRecentSearches))
        userDefaults.set(recentSearches, forKey: Self.recentSearchesKey)
    }

    func clearRecentSearches() {
        recentSearches = []
        userDefaults.removeObject(forKey: Self.recentSearchesKey)
    }
}
