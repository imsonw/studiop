import Dependencies
import SwiftUI

/// Checkout (F-022): address selection (reuses Sprint 6's `SelectAddressSheet`), payment method
/// (a fixed string, no Mollie/WebView integration — Sprint 8's F-024), order creation, success
/// screen. Entered either from Cart's "Checkout" (standard flow) or Product detail's "Buy Now"
/// (skips the cart) — both hand off an already-created `CheckoutSession` to this view's `init`.
struct CheckoutView: View {
    @State private var viewModel: CheckoutViewModel
    @State private var isPresentingAddressSheet = false

    init(session: CheckoutSession) {
        @Dependency(\.storeRepository) var storeRepository

        _viewModel = State(initialValue: CheckoutViewModel(
            session: session,
            updateCheckoutAddressUseCase: UpdateCheckoutAddressUseCase(repository: storeRepository),
            processCheckoutUseCase: ProcessCheckoutUseCase(repository: storeRepository),
            fetchCheckoutSuccessUseCase: FetchCheckoutSuccessUseCase(repository: storeRepository)
        ))
    }

    var body: some View {
        Group {
            if let order = viewModel.completedOrder {
                successView(order: order)
            } else {
                reviewForm
            }
        }
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isPresentingAddressSheet) {
            SelectAddressSheet { address in
                Task { await viewModel.selectAddress(address) }
            }
        }
    }

    private var reviewForm: some View {
        Form {
            Section("Delivery Address") {
                Button {
                    isPresentingAddressSheet = true
                } label: {
                    if let address = viewModel.selectedAddress {
                        VStack(alignment: .leading) {
                            Text(address.fullName)
                            Text("\(address.address), \(address.houseNumber)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Select a delivery address")
                    }
                }
            }

            Section("Items") {
                ForEach(viewModel.session.items, id: \.productId) { item in
                    HStack {
                        Text(item.productName.isEmpty ? item.productId : item.productName)
                        Spacer()
                        Text("x\(item.quantity)")
                        Text(item.unitPrice * Decimal(item.quantity), format: .currency(code: "EUR"))
                    }
                }
            }

            Section("Payment Method") {
                Text(viewModel.paymentMethod.replacingOccurrences(of: "_", with: " ").capitalized)
                    .foregroundStyle(.secondary)
            }

            Section {
                HStack {
                    Text("Subtotal")
                    Spacer()
                    Text(viewModel.session.subtotal, format: .currency(code: "EUR"))
                }
                HStack {
                    Text("Shipping")
                    Spacer()
                    Text(viewModel.session.shippingFee, format: .currency(code: "EUR"))
                }
                HStack {
                    Text("Total").bold()
                    Spacer()
                    Text(viewModel.session.total, format: .currency(code: "EUR")).bold()
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage).foregroundStyle(.red).font(.caption)
            }

            Section {
                Button("Place Order") {
                    Task { await viewModel.placeOrder() }
                }
                .disabled(viewModel.isProcessing || viewModel.selectedAddress == nil)
            }
        }
    }

    private func successView(order: Order) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            Text("Order Placed!").font(.title2.bold())
            Text("Order \(order.code.isEmpty ? order.id : order.code)")
                .foregroundStyle(.secondary)
            Text(order.total, format: .currency(code: "EUR")).font(.title3)
            Spacer()
        }
        .padding(.top, 60)
        .padding()
    }
}
