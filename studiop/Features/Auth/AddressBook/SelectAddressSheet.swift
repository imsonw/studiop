import Dependencies
import SwiftUI

/// Reusable "pick a saved address" bottom sheet (F-014's acceptance criteria) -- Sprint 7's
/// checkout (F-022) presents this same component rather than rebuilding its own address list.
struct SelectAddressSheet: View {
    @State private var viewModel: AddressListViewModel
    @Environment(\.dismiss) private var dismiss
    let onSelect: (Address) -> Void

    init(onSelect: @escaping (Address) -> Void) {
        self.onSelect = onSelect

        @Dependency(\.addressRepository) var addressRepository

        _viewModel = State(initialValue: AddressListViewModel(
            listAddressesUseCase: ListAddressesUseCase(repository: addressRepository),
            updateAddressUseCase: UpdateAddressUseCase(repository: addressRepository),
            deleteAddressUseCase: DeleteAddressUseCase(repository: addressRepository)
        ))
    }

    var body: some View {
        NavigationStack {
            List(viewModel.addresses) { address in
                Button {
                    onSelect(address)
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(address.fullName)
                            .font(.headline)
                        Text("\(address.address), \(address.houseNumber)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Select Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.addresses.isEmpty {
                    Text("No saved addresses yet.")
                        .foregroundStyle(.secondary)
                }
            }
            .task {
                await viewModel.load()
            }
        }
    }
}

#Preview {
    SelectAddressSheet(onSelect: { _ in })
}
