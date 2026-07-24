import SwiftUI

/// Tiered-price add-to-cart bottom sheet (F-021's acceptance criterion) — reachable from Product
/// detail (F-018, has the full `Product` with `priceTiers` already loaded) and the Storefront
/// grid's quick-add (F-017, fetches the full `Product` first since `ProductSummary` doesn't carry
/// tiers — see `StorefrontViewModel.quickAdd`).
struct AddToCartSheet: View {
    let product: Product
    let onAddToCart: (String, Int) async -> Void
    let onBuyNow: ((String, Int) async -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var selectedPriceType: String
    @State private var quantity: Int = 1

    init(
        product: Product,
        onAddToCart: @escaping (String, Int) async -> Void,
        onBuyNow: ((String, Int) async -> Void)? = nil
    ) {
        self.product = product
        self.onAddToCart = onAddToCart
        self.onBuyNow = onBuyNow
        _selectedPriceType = State(initialValue: product.priceTiers.first?.priceType ?? "retail")
    }

    var body: some View {
        NavigationStack {
            Form {
                if !product.priceTiers.isEmpty {
                    Section("Price Tier") {
                        Picker("Tier", selection: $selectedPriceType) {
                            ForEach(product.priceTiers, id: \.priceType) { tier in
                                Text("\(tier.priceType) — \(tier.price, format: .currency(code: "EUR"))")
                                    .tag(tier.priceType)
                            }
                        }
                        .pickerStyle(.inline)
                    }
                }

                Section("Quantity") {
                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...99)
                }

                Section {
                    Button("Add to Cart") {
                        Task {
                            await onAddToCart(selectedPriceType, quantity)
                            dismiss()
                        }
                    }

                    if let onBuyNow {
                        Button("Buy Now") {
                            Task {
                                await onBuyNow(selectedPriceType, quantity)
                                dismiss()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle(product.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
