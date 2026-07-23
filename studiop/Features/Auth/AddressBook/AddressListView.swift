import Dependencies
import SwiftUI

struct AddressListView: View {
    @State private var viewModel: AddressListViewModel
    @State private var isAddingAddress = false
    @State private var editingAddress: Address?

    init() {
        @Dependency(\.addressRepository) var addressRepository

        _viewModel = State(initialValue: AddressListViewModel(
            listAddressesUseCase: ListAddressesUseCase(repository: addressRepository),
            updateAddressUseCase: UpdateAddressUseCase(repository: addressRepository),
            deleteAddressUseCase: DeleteAddressUseCase(repository: addressRepository)
        ))
    }

    var body: some View {
        List {
            ForEach(viewModel.addresses) { address in
                Button {
                    editingAddress = address
                } label: {
                    AddressRow(address: address)
                }
                .buttonStyle(.plain)
                .swipeActions {
                    Button("Delete", role: .destructive) {
                        Task { await viewModel.delete(address) }
                    }
                    if !address.isDefault {
                        Button("Set Default") {
                            Task { await viewModel.setDefault(address) }
                        }
                        .tint(.blue)
                    }
                }
            }

            if viewModel.isLoading {
                ProgressView()
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
        .navigationTitle("Address Book")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { isAddingAddress = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            await viewModel.load()
        }
        .sheet(isPresented: $isAddingAddress) {
            NavigationStack {
                AddressFormView(existingAddress: nil) {
                    Task { await viewModel.load() }
                }
            }
        }
        .sheet(item: $editingAddress) { address in
            NavigationStack {
                AddressFormView(existingAddress: address) {
                    Task { await viewModel.load() }
                }
            }
        }
    }
}

private struct AddressRow: View {
    let address: Address

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(address.fullName)
                    .font(.headline)
                if address.isDefault {
                    Text("Default")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.15), in: Capsule())
                        .foregroundStyle(.blue)
                }
            }
            Text(address.phone)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("\(address.address), \(address.houseNumber)")
                .font(.subheadline)
            if !address.location.isEmpty {
                Text(address.location)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        AddressListView()
    }
}
