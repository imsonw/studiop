import Foundation

@MainActor
@Observable
final class FavoritesViewModel {
    private(set) var filters: [StudioInteractionFilter] = []
    private(set) var studios: [StudioProfile] = []
    var selectedFilterType: String = "follow"
    var isLoading = false
    var errorMessage: String?

    private let fetchStudioInteractionFiltersUseCase: FetchStudioInteractionFiltersUseCase
    private let listStudioInteractionsUseCase: ListStudioInteractionsUseCase
    private let toggleStudioInteractionUseCase: ToggleStudioInteractionUseCase

    init(
        fetchStudioInteractionFiltersUseCase: FetchStudioInteractionFiltersUseCase,
        listStudioInteractionsUseCase: ListStudioInteractionsUseCase,
        toggleStudioInteractionUseCase: ToggleStudioInteractionUseCase
    ) {
        self.fetchStudioInteractionFiltersUseCase = fetchStudioInteractionFiltersUseCase
        self.listStudioInteractionsUseCase = listStudioInteractionsUseCase
        self.toggleStudioInteractionUseCase = toggleStudioInteractionUseCase
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            filters = try await fetchStudioInteractionFiltersUseCase()
            await loadStudios()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func selectFilter(_ type: String) async {
        selectedFilterType = type
        await loadStudios()
    }

    func loadStudios() async {
        isLoading = true
        errorMessage = nil
        do {
            studios = try await listStudioInteractionsUseCase(type: selectedFilterType, limit: 20, page: 1)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func toggleFollow(_ studio: StudioProfile) async {
        do {
            try await toggleStudioInteractionUseCase(id: studio.id, type: "follow")
            await loadStudios()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
