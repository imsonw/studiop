import Dependencies
import SwiftUI

/// Search (F-019): debounced autocomplete + submit via `fetchProductList(query:)`, recent
/// searches persisted locally (no backend endpoint for this), suggested products via
/// `fetchPopularProducts`.
struct SearchView: View {
    @State private var viewModel: SearchViewModel

    init() {
        @Dependency(\.storeRepository) var storeRepository

        _viewModel = State(initialValue: SearchViewModel(
            fetchProductListUseCase: FetchProductListUseCase(repository: storeRepository),
            fetchPopularProductsUseCase: FetchPopularProductsUseCase(repository: storeRepository)
        ))
    }

    var body: some View {
        List {
            if viewModel.query.isEmpty {
                if !viewModel.recentSearches.isEmpty {
                    Section {
                        ForEach(viewModel.recentSearches, id: \.self) { term in
                            Button(term) { viewModel.query = term }
                        }
                    } header: {
                        HStack {
                            Text("Recent Searches")
                            Spacer()
                            Button("Clear") { viewModel.clearRecentSearches() }
                                .font(.caption)
                        }
                    }
                }

                Section("Suggested") {
                    ForEach(viewModel.suggestedProducts) { product in
                        productRow(product)
                    }
                }
            } else {
                if viewModel.isLoading {
                    ProgressView()
                }
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage).foregroundStyle(.red).font(.caption)
                }
                ForEach(viewModel.results) { product in
                    productRow(product)
                }
            }
        }
        .searchable(text: $viewModel.query, prompt: "Search products")
        .onSubmit(of: .search) {
            Task { await viewModel.submitSearch() }
        }
        .navigationTitle("Search")
        .task { await viewModel.loadSuggestions() }
    }

    private func productRow(_ product: ProductSummary) -> some View {
        NavigationLink {
            ProductDetailView(idEncode: product.id)
        } label: {
            HStack {
                CachedAsyncImageView(urlString: product.imageURL)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                VStack(alignment: .leading) {
                    Text(product.name)
                    Text(product.price, format: .currency(code: "EUR"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
