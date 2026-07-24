import Dependencies
import SwiftUI

/// Product detail (F-018): image carousel, seller card, tiered pricing, related products, rating
/// summary. Full review list is Sprint 8 scope (needs `ReviewRepositoryImpl`, not built yet) — see
/// sprint-007/sprint_plan@v1.yaml's F-018 scope note; only `Product.rating`/`ratingCount` (already
/// on the entity, zero new Data layer) are shown here.
struct ProductDetailView: View {
    @State private var viewModel: ProductDetailViewModel
    @State private var isPresentingAddToCart = false
    @State private var checkoutSession: CheckoutSession?

    init(idEncode: String) {
        @Dependency(\.storeRepository) var storeRepository
        @Dependency(\.imageLoading) var imageLoading

        _viewModel = State(initialValue: ProductDetailViewModel(
            idEncode: idEncode,
            fetchProductDetailUseCase: FetchProductDetailUseCase(repository: storeRepository),
            fetchRelatedProductsUseCase: FetchRelatedProductsUseCase(repository: storeRepository),
            addToCartUseCase: AddToCartUseCase(repository: storeRepository),
            buyNowUseCase: BuyNowUseCase(repository: storeRepository),
            imageLoading: imageLoading
        ))
    }

    var body: some View {
        ScrollView {
            if let product = viewModel.product {
                VStack(alignment: .leading, spacing: 16) {
                    imageCarousel(images: product.images)

                    Text(product.name)
                        .font(.title2.bold())

                    ratingSummary(product: product)

                    if let brandName = product.brandName {
                        Text("Sold by \(brandName)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    priceTiers(product: product)

                    Text(product.description)
                        .font(.body)

                    if let cartMessage = viewModel.cartMessage {
                        Text(cartMessage)
                            .foregroundStyle(.green)
                            .font(.caption)
                    }
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }

                    Button("Add to Cart / Buy Now") {
                        isPresentingAddToCart = true
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .disabled(viewModel.isAddingToCart)

                    if !viewModel.relatedProducts.isEmpty {
                        relatedProductsSection
                    }
                }
                .padding()
            } else if viewModel.isLoading {
                ProgressView().padding(.top, 60)
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage).foregroundStyle(.red).padding()
            }
        }
        .navigationTitle("Product")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .sheet(isPresented: $isPresentingAddToCart) {
            if let product = viewModel.product {
                AddToCartSheet(
                    product: product,
                    onAddToCart: { priceType, quantity in
                        await viewModel.addToCart(priceType: priceType, quantity: quantity)
                    },
                    onBuyNow: { priceType, quantity in
                        checkoutSession = await viewModel.buyNow(priceType: priceType, quantity: quantity)
                    }
                )
            }
        }
        .navigationDestination(item: $checkoutSession) { session in
            CheckoutView(session: session)
        }
    }

    private func imageCarousel(images: [String]) -> some View {
        TabView {
            ForEach(images, id: \.self) { imageURL in
                CachedAsyncImageView(urlString: imageURL)
                    .aspectRatio(1, contentMode: .fit)
            }
        }
        .tabViewStyle(.page)
        .frame(height: 300)
    }

    private func ratingSummary(product: Product) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill").foregroundStyle(.yellow)
            Text(String(format: "%.1f", product.rating))
            Text("(\(product.ratingCount) reviews)")
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
    }

    private func priceTiers(product: Product) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(product.priceTiers, id: \.priceType) { tier in
                HStack {
                    Text(tier.priceType.capitalized)
                    Spacer()
                    if let compareAtPrice = tier.compareAtPrice {
                        Text(compareAtPrice, format: .currency(code: "EUR"))
                            .strikethrough()
                            .foregroundStyle(.secondary)
                    }
                    Text(tier.price, format: .currency(code: "EUR"))
                        .bold()
                }
            }
        }
    }

    private var relatedProductsSection: some View {
        VStack(alignment: .leading) {
            Text("Related Products").font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.relatedProducts) { related in
                        NavigationLink {
                            ProductDetailView(idEncode: related.id)
                        } label: {
                            VStack {
                                CachedAsyncImageView(urlString: related.imageURL)
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                Text(related.name)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .frame(width: 100)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
