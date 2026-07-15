import Foundation

@MainActor
@Observable
final class LoginViewModel {
    var email = ValidatedField<String>(value: "")
    var password: String = ""
    var errorMessage: String?
    var isLoading: Bool = false

    private let loginUseCase: LoginUseCase
    private let fetchUserInfoUseCase: FetchUserInfoUseCase
    private let keychainStore: KeychainStoring
    private let appState: AppState

    init(
        loginUseCase: LoginUseCase,
        fetchUserInfoUseCase: FetchUserInfoUseCase,
        keychainStore: KeychainStoring,
        appState: AppState
    ) {
        self.loginUseCase = loginUseCase
        self.fetchUserInfoUseCase = fetchUserInfoUseCase
        self.keychainStore = keychainStore
        self.appState = appState
    }

    func login() async {
        email.error = AuthFieldValidator.validateEmail(email.value)?.localizedMessage
        guard email.error == nil else { return }

        isLoading = true
        errorMessage = nil

        do {
            let session = try await loginUseCase(email: email.value, password: password)

            keychainStore.writeToken(session.token)

            _ = try await fetchUserInfoUseCase()

            appState.isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
