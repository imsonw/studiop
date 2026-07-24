import Dependencies
import SwiftUI

/// Favorites (F-020, scope narrowed to followed/liked shops — see sprint-007/sprint_plan@v1.yaml's
/// F-020 scope note; flash-sale and "today's suggestion" are excluded, no documented endpoint).
struct FavoritesView: View {
    @State private var viewModel: FavoritesViewModel

    init() {
        @Dependency(\.studioRepository) var studioRepository

        _viewModel = State(initialValue: FavoritesViewModel(
            fetchStudioInteractionFiltersUseCase: FetchStudioInteractionFiltersUseCase(repository: studioRepository),
            listStudioInteractionsUseCase: ListStudioInteractionsUseCase(repository: studioRepository),
            toggleStudioInteractionUseCase: ToggleStudioInteractionUseCase(repository: studioRepository)
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(viewModel.filters) { filter in
                        Button(filter.label) {
                            Task { await viewModel.selectFilter(filter.type) }
                        }
                        .buttonStyle(.bordered)
                        .tint(viewModel.selectedFilterType == filter.type ? .accentColor : .gray)
                    }
                }
                .padding()
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage).foregroundStyle(.red).font(.caption)
            }

            List(viewModel.studios) { studio in
                HStack {
                    VStack(alignment: .leading) {
                        Text(studio.name)
                        Text("\(studio.followerCount) followers")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(studio.isFollowing ? "Following" : "Follow") {
                        Task { await viewModel.toggleFollow(studio) }
                    }
                    .buttonStyle(.bordered)
                }
            }
            .overlay {
                if viewModel.isLoading && viewModel.studios.isEmpty {
                    ProgressView()
                }
            }
        }
        .navigationTitle("Favorites")
        .task { await viewModel.load() }
    }
}
