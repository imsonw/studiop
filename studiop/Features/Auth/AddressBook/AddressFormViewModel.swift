import Foundation

@MainActor
@Observable
final class AddressFormViewModel {
    var fullName = ValidatedField<String>(value: "")
    var phone = ValidatedField<String>(value: "")
    var address = ValidatedField<String>(value: "")
    var houseNumber = ValidatedField<String>(value: "")
    var postalCode = ValidatedField<String>(value: "")
    var location = ValidatedField<String>(value: "")
    var country = ValidatedField<String>(value: "")
    var isDefault: Bool = false
    var isLoading: Bool = false
    var errorMessage: String?
    private(set) var didSave: Bool = false

    private let existingAddressID: Int?
    private let createAddressUseCase: CreateAddressUseCase
    private let updateAddressUseCase: UpdateAddressUseCase

    var isEditing: Bool { existingAddressID != nil }

    init(
        existingAddress: Address?,
        createAddressUseCase: CreateAddressUseCase,
        updateAddressUseCase: UpdateAddressUseCase
    ) {
        existingAddressID = existingAddress?.id
        self.createAddressUseCase = createAddressUseCase
        self.updateAddressUseCase = updateAddressUseCase

        if let existingAddress {
            fullName.value = existingAddress.fullName
            phone.value = existingAddress.phone
            address.value = existingAddress.address
            houseNumber.value = existingAddress.houseNumber
            postalCode.value = existingAddress.postalCode
            location.value = existingAddress.location
            country.value = existingAddress.country
            isDefault = existingAddress.isDefault
        }
    }

    private static func requiredFieldError(_ value: String) -> String? {
        value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "This field is required" : nil
    }

    func save() async {
        fullName.error = Self.requiredFieldError(fullName.value)
        phone.error = Self.requiredFieldError(phone.value)
        address.error = Self.requiredFieldError(address.value)
        houseNumber.error = Self.requiredFieldError(houseNumber.value)
        postalCode.error = Self.requiredFieldError(postalCode.value)
        country.error = Self.requiredFieldError(country.value)

        guard
            fullName.error == nil, phone.error == nil, address.error == nil,
            houseNumber.error == nil, postalCode.error == nil, country.error == nil
        else {
            return
        }

        isLoading = true
        errorMessage = nil

        let candidate = Address(
            id: existingAddressID,
            fullName: fullName.value,
            phone: phone.value,
            address: address.value,
            houseNumber: houseNumber.value,
            postalCode: postalCode.value,
            location: location.value,
            country: country.value,
            isDefault: isDefault
        )

        do {
            if let id = existingAddressID {
                _ = try await updateAddressUseCase(id: id, candidate)
            } else {
                _ = try await createAddressUseCase(candidate)
            }
            didSave = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
