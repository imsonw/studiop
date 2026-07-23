import Foundation

@MainActor
@Observable
final class ProfileViewModel {
    var name = ValidatedField<String>(value: "")
    var email = ValidatedField<String>(value: "")
    var phone = ValidatedField<String>(value: "")
    var companyName = ValidatedField<String>(value: "")
    var taxCode = ValidatedField<String>(value: "")
    var isLoading: Bool = false
    var errorMessage: String?
    var successMessage: String?

    var currentPassword: String = ""
    var newPassword: String = ""
    var isChangingPassword: Bool = false
    var passwordErrorMessage: String?
    var passwordSuccessMessage: String?

    private let fetchUserInfoUseCase: FetchUserInfoUseCase
    private let changeUserProfileUseCase: ChangeUserProfileUseCase
    private let changePasswordUseCase: ChangePasswordUseCase
    private let biometricCredentialStore: BiometricCredentialStoring

    init(
        fetchUserInfoUseCase: FetchUserInfoUseCase,
        changeUserProfileUseCase: ChangeUserProfileUseCase,
        changePasswordUseCase: ChangePasswordUseCase,
        biometricCredentialStore: BiometricCredentialStoring
    ) {
        self.fetchUserInfoUseCase = fetchUserInfoUseCase
        self.changeUserProfileUseCase = changeUserProfileUseCase
        self.changePasswordUseCase = changePasswordUseCase
        self.biometricCredentialStore = biometricCredentialStore
    }

    func loadProfile() async {
        isLoading = true
        errorMessage = nil
        do {
            let user = try await fetchUserInfoUseCase()
            name.value = user.name
            email.value = user.email
            phone.value = user.phone ?? ""
            companyName.value = user.companyName ?? ""
            taxCode.value = user.taxCode ?? ""
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func saveProfile() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        do {
            _ = try await changeUserProfileUseCase(
                name: name.value,
                phone: phone.value.isEmpty ? nil : phone.value,
                email: email.value,
                companyName: companyName.value.isEmpty ? nil : companyName.value,
                taxCode: taxCode.value.isEmpty ? nil : taxCode.value
            )
            successMessage = "Profile updated."
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func changePassword() async {
        isChangingPassword = true
        passwordErrorMessage = nil
        passwordSuccessMessage = nil
        do {
            try await changePasswordUseCase(currentPassword: currentPassword, newPassword: newPassword)
            // A changed password invalidates any biometric pairing tied to the old credentials --
            // mirrors BiometricCubit.clearLocalBiometricData's documented call site.
            biometricCredentialStore.clear()
            passwordSuccessMessage = "Password changed."
            currentPassword = ""
            newPassword = ""
        } catch {
            passwordErrorMessage = error.localizedDescription
        }
        isChangingPassword = false
    }
}
