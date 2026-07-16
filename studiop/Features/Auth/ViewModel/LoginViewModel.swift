import Foundation

@MainActor
@Observable
final class LoginViewModel {
    var email = ValidatedField<String>(value: "")
    var password: String = ""
    var errorMessage: String?
    var isLoading: Bool = false
    /// Set when a social login succeeds but the provider didn't share an email (e.g. Apple only
    /// supplies one on the very first authorization) -- LoginView pushes CollectEmailView when true.
    var needsEmailCollection: Bool = false

    private let loginUseCase: LoginUseCase
    private let loginWithSocialUseCase: LoginWithSocialUseCase
    private let fetchUserInfoUseCase: FetchUserInfoUseCase
    private let keychainStore: KeychainStoring
    private let appState: AppState

    init(
        loginUseCase: LoginUseCase,
        loginWithSocialUseCase: LoginWithSocialUseCase,
        fetchUserInfoUseCase: FetchUserInfoUseCase,
        keychainStore: KeychainStoring,
        appState: AppState
    ) {
        self.loginUseCase = loginUseCase
        self.loginWithSocialUseCase = loginWithSocialUseCase
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

    func appleSignInFailed(_ error: Error) {
        errorMessage = error.localizedDescription
    }

    /// `provider` is sent to the backend as-is ("apple") -- not yet confirmed against real
    /// captured traffic what literal value this backend expects, same caveat as the other
    /// DTO-shape assumptions flagged in docs/api-reference.md.
    func loginWithApple(_ credential: AppleSignInCredential) async {
        isLoading = true
        errorMessage = nil

        do {
            let session = try await loginWithSocialUseCase(
                provider: "apple",
                socialToken: credential.identityToken,
                socialEmail: credential.email,
                socialUserId: credential.userIdentifier,
                socialName: credential.fullName
            )

            keychainStore.writeToken(session.token)

            let user = try await fetchUserInfoUseCase()

            if user.email.isEmpty {
                needsEmailCollection = true
            } else {
                appState.isAuthenticated = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
