import Foundation

@MainActor
@Observable
final class AddressListViewModel {
    var addresses: [Address] = []
    var isLoading: Bool = false
    var errorMessage: String?

    private let listAddressesUseCase: ListAddressesUseCase
    private let updateAddressUseCase: UpdateAddressUseCase
    private let deleteAddressUseCase: DeleteAddressUseCase

    init(
        listAddressesUseCase: ListAddressesUseCase,
        updateAddressUseCase: UpdateAddressUseCase,
        deleteAddressUseCase: DeleteAddressUseCase
    ) {
        self.listAddressesUseCase = listAddressesUseCase
        self.updateAddressUseCase = updateAddressUseCase
        self.deleteAddressUseCase = deleteAddressUseCase
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            addresses = try await listAddressesUseCase()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func delete(_ address: Address) async {
        guard let id = address.id else { return }
        errorMessage = nil
        do {
            try await deleteAddressUseCase(id: id)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// No dedicated set-default endpoint exists (docs/api-reference.md) — `isDefault` is toggled
    /// via a normal update call, then the list is reloaded so exactly-one-default reflects the
    /// server's own truth rather than being guessed client-side.
    func setDefault(_ address: Address) async {
        guard let id = address.id else { return }
        errorMessage = nil
        var updated = address
        updated.isDefault = true
        do {
            _ = try await updateAddressUseCase(id: id, updated)
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
