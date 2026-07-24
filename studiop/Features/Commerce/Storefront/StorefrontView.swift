import Dependencies
import SwiftUI

/// Storefront tab: category browse, product grid, brand listing (F-017). Temporary top-level
/// entry point bridged from `HomeView` until the real bottom tab shell exists (Sprint 9's F-028),
/// same shape as Sprint 6's "Account" bridge.
struct StorefrontView: View {
    @State private var viewModel: StorefrontViewModel

    private static let columns = [GridItem(.flexible()), GridItem(.flexible())]

    init() {
        @Dependency(\.storeRepository) var storeRepository
        @Dependency(\.imageLoading) var imageLoading

        _viewModel = State(initialValue: StorefrontViewModel(
            fetchCategoriesUseCase: FetchCategoriesUseCase(repository: storeRepository),
            fetchProductListUseCase: FetchProductListUseCase(repository: storeRepository),
            fetchBrandListUseCase: FetchBrandListUseCase(repository: storeRepository),
            imageLoading: imageLoading
        ))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    categoryChips

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }

                    if viewModel.isLoading && viewModel.products.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)
                    } else {
                        productGrid
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Store")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink("Cart") {
                        CartView()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink("Search") {
                        SearchView()
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink("Brands (\(viewModel.brands.count))") {
                        BrandListView(brands: viewModel.brands)
                    }
                }
            }
            .task {
                await viewModel.load()
            }
        }
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryChip(title: "All", id: nil)
                ForEach(viewModel.categories) { category in
                    categoryChip(title: category.name, id: category.id)
                }
            }
            .padding(.horizontal)
        }
    }

    private func categoryChip(title: String, id: String?) -> some View {
        Button(title) {
            Task { await viewModel.selectCategory(id) }
        }
        .buttonStyle(.bordered)
        .tint(viewModel.selectedCategoryId == id ? .accentColor : .gray)
    }

    private var productGrid: some View {
        LazyVGrid(columns: Self.columns, spacing: 12) {
            ForEach(viewModel.products) { product in
                NavigationLink {
                    ProductDetailView(idEncode: product.id)
                } label: {
                    ProductGridCell(product: product)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }
}

private struct ProductGridCell: View {
    let product: ProductSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            CachedAsyncImageView(urlString: product.imageURL)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(product.name)
                .font(.caption)
                .lineLimit(2)
            Text(product.price, format: .currency(code: "EUR"))
                .font(.caption.bold())
        }
    }
}

private struct BrandListView: View {
    let brands: [Brand]

    var body: some View {
        List(brands) { brand in
            Text(brand.name)
        }
        .navigationTitle("Brands")
    }
}

#Preview {
    StorefrontView()
}
