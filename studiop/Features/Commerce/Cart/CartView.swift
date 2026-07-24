import Dependencies
import SwiftUI

/// Cart (F-021): list/update/remove/clear/count, "checkout" hands off to F-022 via
/// `createCheckout`.
struct CartView: View {
    @State private var viewModel: CartViewModel
    @State private var checkoutSession: CheckoutSession?

    init() {
        @Dependency(\.storeRepository) var storeRepository

        _viewModel = State(initialValue: CartViewModel(
            listCartUseCase: ListCartUseCase(repository: storeRepository),
            updateCartUseCase: UpdateCartUseCase(repository: storeRepository),
            removeFromCartUseCase: RemoveFromCartUseCase(repository: storeRepository),
            clearCartUseCase: ClearCartUseCase(repository: storeRepository),
            createCheckoutUseCase: CreateCheckoutUseCase(repository: storeRepository)
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage).foregroundStyle(.red).font(.caption).padding(.top, 4)
            }

            List {
                ForEach(viewModel.items) { item in
                    HStack {
                        CachedAsyncImageView(urlString: item.productImageURL)
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                        VStack(alignment: .leading) {
                            Text(item.productName.isEmpty ? item.productId : item.productName)
                            Text(item.unitPrice, format: .currency(code: "EUR"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Stepper(
                            "\(item.quantity)",
                            value: Binding(
                                get: { item.quantity },
                                set: { newValue in
                                    Task { await viewModel.updateQuantity(productId: item.productId, quantity: newValue) }
                                }
                            ),
                            in: 0...99
                        )
                        .fixedSize()
                    }
                    .swipeActions {
                        Button("Remove", role: .destructive) {
                            Task { await viewModel.remove(productId: item.productId) }
                        }
                    }
                }
            }
            .overlay {
                if viewModel.isLoading && viewModel.items.isEmpty {
                    ProgressView()
                } else if viewModel.items.isEmpty {
                    Text("Your cart is empty.").foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 12) {
                HStack {
                    Text("Total").font(.headline)
                    Spacer()
                    Text(viewModel.total, format: .currency(code: "EUR")).font(.headline)
                }

                Button("Checkout") {
                    Task { checkoutSession = await viewModel.checkout() }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(viewModel.items.isEmpty)
            }
            .padding()
        }
        .navigationTitle("Cart")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Clear") { Task { await viewModel.clear() } }
                    .disabled(viewModel.items.isEmpty)
            }
        }
        .task { await viewModel.load() }
        .navigationDestination(item: $checkoutSession) { session in
            CheckoutView(session: session)
        }
    }
}
