import Dependencies
import SwiftUI

struct AddressFormView: View {
    @State private var viewModel: AddressFormViewModel
    @State private var isPickingLocation = false
    @Environment(\.dismiss) private var dismiss
    let onSaved: () -> Void

    init(existingAddress: Address?, onSaved: @escaping () -> Void) {
        self.onSaved = onSaved

        @Dependency(\.addressRepository) var addressRepository

        _viewModel = State(initialValue: AddressFormViewModel(
            existingAddress: existingAddress,
            createAddressUseCase: CreateAddressUseCase(repository: addressRepository),
            updateAddressUseCase: UpdateAddressUseCase(repository: addressRepository)
        ))
    }

    var body: some View {
        Form {
            Section("Contact") {
                ValidatedTextField(title: "Full name", field: $viewModel.fullName) { value in
                    value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "This field is required" : nil
                }
                ValidatedTextField(title: "Phone", field: $viewModel.phone) { value in
                    value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "This field is required" : nil
                }
                .keyboardType(.phonePad)
            }

            Section("Address") {
                ValidatedTextField(title: "Address", field: $viewModel.address) { value in
                    value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "This field is required" : nil
                }
                ValidatedTextField(title: "House number", field: $viewModel.houseNumber) { value in
                    value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "This field is required" : nil
                }
                ValidatedTextField(title: "Postal code", field: $viewModel.postalCode) { value in
                    value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "This field is required" : nil
                }
                ValidatedTextField(title: "Country", field: $viewModel.country) { value in
                    value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "This field is required" : nil
                }

                ValidatedTextField(title: "Location", field: $viewModel.location) { _ in nil }

                Button("Pick on map") {
                    isPickingLocation = true
                }
            }

            Section {
                Toggle("Set as default address", isOn: $viewModel.isDefault)
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.caption)
            }
        }
        .navigationTitle(viewModel.isEditing ? "Edit Address" : "New Address")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Button("Save") {
                        Task {
                            await viewModel.save()
                            if viewModel.didSave {
                                onSaved()
                                dismiss()
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $isPickingLocation) {
            LocationPickerView { resolvedAddress in
                viewModel.location.value = resolvedAddress
            }
        }
    }
}

#Preview {
    NavigationStack {
        AddressFormView(existingAddress: nil, onSaved: {})
    }
}
