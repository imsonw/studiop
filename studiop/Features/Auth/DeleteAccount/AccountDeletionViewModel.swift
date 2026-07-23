import Foundation

@MainActor
@Observable
final class AccountDeletionViewModel {
    var reason = ValidatedField<String>(value: "")
    var isRequesting: Bool = false
    var requestErrorMessage: String?
    var requestSuccessMessage: String?

    var email = ValidatedField<String>(value: "")
    var code: String = ""
    var isConfirming: Bool = false
    var confirmErrorMessage: String?

    private let requestAccountRemovalUseCase: RequestAccountRemovalUseCase
    private let confirmAccountRemovalUseCase: ConfirmAccountRemovalUseCase
    private let keychainStore: KeychainStoring
    private let appState: AppState

    init(
        requestAccountRemovalUseCase: RequestAccountRemovalUseCase,
        confirmAccountRemovalUseCase: ConfirmAccountRemovalUseCase,
        keychainStore: KeychainStoring,
        appState: AppState
    ) {
        self.requestAccountRemovalUseCase = requestAccountRemovalUseCase
        self.confirmAccountRemovalUseCase = confirmAccountRemovalUseCase
        self.keychainStore = keychainStore
        self.appState = appState
    }

    func requestRemoval() async {
        reason.error = reason.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Please provide a reason"
            : nil
        guard reason.error == nil else { return }

        isRequesting = true
        requestErrorMessage = nil
        requestSuccessMessage = nil

        do {
            try await requestAccountRemovalUseCase(reason: reason.value)
            requestSuccessMessage = "Request submitted. Check your email for a confirmation code."
        } catch {
            requestErrorMessage = error.localizedDescription
        }

        isRequesting = false
    }

    func confirmRemoval() async {
        email.error = AuthFieldValidator.validateEmail(email.value)?.localizedMessage
        guard email.error == nil, !code.isEmpty else { return }

        isConfirming = true
        confirmErrorMessage = nil

        do {
            try await confirmAccountRemovalUseCase(email: email.value, code: code)
            keychainStore.clear()
            appState.isAuthenticated = false
        } catch {
            confirmErrorMessage = error.localizedDescription
        }

        isConfirming = false
    }
}
